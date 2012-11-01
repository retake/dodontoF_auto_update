#! ruby -Ku
# -*- encoding: utf-8 -*-

class Main

  # ライブラリ等指定
  $LOAD_PATH << File.dirname(__FILE__)
  require 'baselibs'
  require 'net/ssh'
  require 'net/scp'
  require 'net/ftp'
  require 'fileutils'
  require 'find'
  require 'stricts'
  require 'yaml'
  require 'libs'
  require 'nokogiri'
  require 'open-uri'
  require 'httpclient'

  ######################### initialize #########################

  # 初期処理
  def initialize(params)
    logging("START : #{self.class.to_s}::#{__method__.to_s}" ,$info)

    # パラメータ設定
    $Str_param_host = params[$Str_varname_param_host]
    $Str_param_proto = params[$Str_varname_param_protocol]
    $Str_param_ssh_user = params[$Str_varname_param_ssh_user]
    $Str_param_ssh_pass = params[$Str_varname_param_ssh_password]
    $Flg_param_sudo_use = params[$Str_varname_param_sudo_flg]
    $Str_param_sudo_pass = params[$Str_varname_param_sudo_password]
    $Str_param_ftp_user = params[$Str_varname_param_ftp_user]
    $Str_param_ftp_pass = params[$Str_varname_param_ftp_password]
    @Str_param_path_dir_dodontof_server = check_dir(params[$Str_varname_param_ddtf_dir])
    @Str_param_path_dir_working_base_server = check_dir(params[$Str_varname_param_work_dir])
    
     
    # cpコマンド修正(sudo時)
    if $Flg_param_sudo_use == $Flg_param_sudo_flg_use then
      @Cmd_cp_fixed = make_sudo($Str_param_sudo_pass , $Cmd_cp) if $Flg_param_sudo_use == $Flg_param_sudo_flg_use
    elsif $Flg_param_sudo_use == $Flg_param_sudo_flg_nouse then
      @Cmd_cp_fixed = $Cmd_cp
    end
    
    
    # protoコマンド修正
    $str_param_proto_flg = ""
    case $Str_param_proto.downcase
    when $Str_param_protocol_value_ssh
      $str_param_proto_flg = $Str_param_protocol_value_ssh
    when $Str_param_protocol_value_ftp
      $str_param_proto_flg = $Str_param_protocol_value_ftp
    end
    
    logging("END   : " + self.class.to_s + "::" + __method__.to_s ,$info)
  end


  ######################### PRE_UPDATE #########################

  # バージョンアップ前段階作業
  def PreUpdate
    logging("START : #{self.class.to_s}::#{__method__.to_s}" ,$info)

    # 共通処理(クライアント作業ディレクトリ作成）
    self.MakeClientWorkDir

    # どどんとふ最新版ダウンロード
    @path_zip_dodontof_newver_client = self.DownloadNewDodontofZip

    # サーバ側作業フォルダ作成/バックアップ
    self.MakeWorkDirOnServer
    
    # zipファイル展開
    self.ExpandNewDodontofZip

    # 新旧コンフィグ準備
    self.DownloadNewAndExistConfigRb

    # 取得したコンフィグを解析（共通）
    self.PerseConfigRb

    # その他情報バックアップ
    self.BackupEtc

    # 引き継ぎ情報取得
    self.DownloadStatuslink

    # 情報連携ファイル作成
    self.MakeStatuslinkYml

    # コンフィグファイル差分修正
    self.MakeConf

    logging("END   : #{self.class.to_s}::#{__method__.to_s}" ,$info)
  end



  ######################### PRE_VER_UP_METHOD #########################

  # 共通処理(クライアント作業ディレクトリ作成）
  def MakeClientWorkDir
    begin
      Dir::mkdir($Path_dir_working_client)
    rescue Errno::EEXIST
      logging("\"#{File.expand_path($Path_dir_working_client)}\" is already exists",$warn)
    end

    begin
      Dir::mkdir($Path_dir_zipexpand_client) if $str_param_proto_flg == $Str_param_protocol_value_ftp
    rescue Errno::EEXIST
      logging("\"#{File.expand_path($Path_dir_zipexpand_client)}\" is already exists",$warn)
    end
  end


  # どどんとふ最新版ダウンロード
  def DownloadNewDodontofZip
    logging("START : #{self.class.to_s}::#{__method__.to_s}" ,$info)
    
    doc = Nokogiri::HTML(open("#{$Uri_base_dodontof_newver}#{$Uri_html_dodontof_newver_from_base}","r:#{$Str_encoding_utf8}").read)
    filename_zip_dodontof_newver = doc.search("a").first["href"].gsub(/^\.\//,"")
    uri_zip_dodontof_newver =  "#{$Uri_base_dodontof_newver}#{filename_zip_dodontof_newver}"
    path_zip_dodontof_newver_client = File.expand_path("#{$Path_dir_working_client}#{filename_zip_dodontof_newver}")
    hc = HTTPClient.new
    f = File.open(path_zip_dodontof_newver_client, "wb")
      f.print(hc.get_content(uri_zip_dodontof_newver))
    f.close
    
    logging("END   : #{self.class.to_s}::#{__method__.to_s}" ,$info)
    path_zip_dodontof_newver_client
  end


  # サーバ側作業フォルダ作成/バックアップ
  def MakeWorkDirOnServer
    logging("START : #{self.class.to_s}::#{__method__.to_s}" ,$info)
    if $str_param_proto_flg == $Str_param_protocol_value_ssh then
      @path_dir_working_server = ''
      @path_dir_backup_server = ''
      @path_dir_dodontof_newver_server = ''
      @path_zip_dodontof_newver_server = ''

      # SSH接続（作業フォルダ作成・バックアップ）
      Net::SSH.start($Str_param_host, $Str_param_ssh_user, :password => $Str_param_ssh_pass) do |ssh|
      
        # 今回作業用フォルダを作成
        @path_dir_working_server = check_dir(@Str_param_path_dir_working_base_server + delete_crlf(invoke(ssh , "#{$Cmd_date}")))
        invoke(ssh, "#{$Cmd_mkdir} #{@path_dir_working_server}" ) 
        
        # バックアップ用フォルダ、新バージョン用フォルダを作成
        @path_dir_backup_server = "#{@path_dir_working_server}#{$Path_dir_backup_from_backup_base}"
        @path_dir_dodontof_newver_server = "#{@path_dir_working_server}#{$Path_dir_newver_from_backup_base}"
        invoke(ssh, "#{$Cmd_mkdir} #{@path_dir_backup_server}" )
        invoke(ssh, "#{$Cmd_mkdir} #{@path_dir_dodontof_newver_server}" )
        
        # バックアップ実行(メインディレクトリ、コンフィグ）
        invoke(ssh, "#{$Cmd_tar_comp} #{@path_dir_backup_server}#{$Filename_tar_backup_dodontof} #{@Str_param_path_dir_dodontof_server}*" )
        invoke(ssh, "#{@Cmd_cp_fixed} #{@Str_param_path_dir_dodontof_server}#{$Path_rb_config_from_dodontof_dir} #{@path_dir_backup_server}#{$Filename_rb_config_default}" )
      end
    elsif $str_param_proto_flg == $Str_param_protocol_value_ftp then
      # 無し
    end
    logging("END   : #{self.class.to_s}::#{__method__.to_s}" ,$info)
  end

  # zipファイル展開
  def ExpandNewDodontofZip
    logging("START : #{self.class.to_s}::#{__method__.to_s}" ,$info)
    if $str_param_proto_flg == $Str_param_protocol_value_ssh then
      # SCP接続（新バージョンのzipファイルを送信）
      Net::SCP.start($Str_param_host, $Str_param_ssh_user, :password => $Str_param_ssh_pass) do|scp|
        @path_zip_dodontof_newver_server =  "#{@path_dir_dodontof_newver_server}#{File.basename(@path_zip_dodontof_newver_client)}"
        channel = scp.upload(@path_zip_dodontof_newver_client , @path_zip_dodontof_newver_server )
        channel.wait
      end
      # SSH接続（zip解凍）
      Net::SSH.start($Str_param_host, $Str_param_ssh_user, :password => $Str_param_ssh_pass) do |ssh|
        # zip解凍
        invoke_nomsg(ssh, "#{$Cmd_zip_exp} #{@path_dir_dodontof_newver_server} #{@path_zip_dodontof_newver_server}" )
      end
    elsif $str_param_proto_flg == $Str_param_protocol_value_ftp then
      # クライアントでzipを解凍
      ore_unzip(@path_zip_dodontof_newver_client , $Path_dir_zipexpand_client)
    end
    logging("END   : #{self.class.to_s}::#{__method__.to_s}" ,$info)
  end

  # 新旧コンフィグ準備
  def DownloadNewAndExistConfigRb
    logging("START : #{self.class.to_s}::#{__method__.to_s}" ,$debug)
    if $str_param_proto_flg == $Str_param_protocol_value_ssh then
      # 新旧コンフィグ取得
      Net::SCP.start($Str_param_host, $Str_param_ssh_user, :password => $Str_param_ssh_pass) do|scp|
        channel = scp.download( "#{@path_dir_dodontof_newver_server}#{$Path_dir_dodontof_default}#{$Path_rb_config_from_dodontof_dir}" , "#{$Path_dir_working_client}#{$Filename_rb_config_newver_client}" )
        channel.wait
        channel = scp.download( "#{@path_dir_backup_server}config.rb" , "#{$Path_dir_working_client}#{$Filename_rb_config_existing_client}" )
        channel.wait
      end
    elsif $str_param_proto_flg == $Str_param_protocol_value_ftp then
      # 現行のコンフィグを取得
      Net::FTP.open($Str_param_host, $Str_param_ftp_user, $Str_param_ftp_pass) do |ftp|
        ftp.passive = true
        ftp.getbinaryfile( "#{@Str_param_path_dir_dodontof_server}#{$Path_rb_config_from_dodontof_dir}" , "#{$Path_dir_working_client}#{$Filename_rb_config_existing_client}" )      
        ftp.close
      end
      # 新コンフィグの雛形をコピー
      FileUtils.copy( "#{$Path_dir_zipexpand_client}#{$Path_dir_dodontof_default}#{$Path_rb_config_from_dodontof_dir}" , "#{$Path_dir_working_client}#{$Filename_rb_config_newver_client}" )
    end
    logging("END   : #{self.class.to_s}::#{__method__.to_s}" ,$debug)
  end
  
  

  # 取得したコンフィグを解析（共通）
  def PerseConfigRb
    logging("START : #{self.class.to_s}::#{__method__.to_s}" ,$debug)
    rbconf_params = parse_rbconf("#{$Path_dir_working_client}#{$Filename_rb_config_existing_client}")
    
    @str_rbparam_filename_loginmessagefile = rbconf_params[$Str_varname_rb_config_loginmessagefile]
    @str_rbparam_dir_imagedirpath = rbconf_params[$Str_varname_rb_config_imagedirpath]
    @str_rbparam_dir_savedirpath = rbconf_params[$Str_varname_rb_config_savedirpath]
    logging("END   : #{self.class.to_s}::#{__method__.to_s}" ,$debug)
  end
  
  

  # その他情報バックアップ
  def BackupEtc
    logging("START : #{self.class.to_s}::#{__method__.to_s}" ,$debug)
    if $str_param_proto_flg == $Str_param_protocol_value_ssh then
      # SSH接続（ログインメッセージ、uploadImageSpace,saveDataバックアップ）
      Net::SSH.start($Str_param_host, $Str_param_ssh_user, :password => $Str_param_ssh_pass) do |ssh|
        open( "#{$Path_dir_working_client}#{$Filename_rb_config_existing_client}" , "r:#{$Str_encoding_utf8}" ) { |file|
          # ログインメッセージバックアップ
          invoke(ssh, "#{@Cmd_cp_fixed} #{@Str_param_path_dir_dodontof_server}#{@str_rbparam_filename_loginmessagefile} #{@path_dir_backup_server}#{@str_rbparam_filename_loginmessagefile}" )
          # imageUploadSpaceバックアップ
          invoke(ssh, "#{$Cmd_cd} #{@Str_param_path_dir_dodontof_server} ; #{$Cmd_tar_comp} #{@path_dir_backup_server}#{$Filename_tar_backup_imageuploadspace} #{@str_rbparam_dir_imagedirpath}/* ")
          # saveDataバックアップ
          invoke(ssh, "#{$Cmd_cd} #{@Str_param_path_dir_dodontof_server} ; #{$Cmd_tar_comp} #{@path_dir_backup_server}#{$Filename_tar_backup_save} #{@str_rbparam_dir_savedirpath}/* ")
        }
      end
    elsif $str_param_proto_flg == $Str_param_protocol_value_ftp then
      # なし
    end
    logging("END   : #{self.class.to_s}::#{__method__.to_s}" ,$debug)
  end



  # 引き継ぎ情報取得
  def DownloadStatuslink
    logging("START : #{self.class.to_s}::#{__method__.to_s}" ,$debug)
    if $str_param_proto_flg == $Str_param_protocol_value_ssh then
      Net::SCP.start($Str_param_host, $Str_param_ssh_user, :password => $Str_param_ssh_pass) do|scp|
        channel = scp.download( "#{@path_dir_backup_server}#{@str_rbparam_filename_loginmessagefile}" , "#{$Path_dir_working_client}#{$Filename_html_loginmessage_client}" )
        channel.wait
      end
    elsif $str_param_proto_flg == $Str_param_protocol_value_ftp then
      Net::FTP.open($Str_param_host, $Str_param_ftp_user, $Str_param_ftp_pass) do |ftp|
        ftp.passive = true
        ftp.gettextfile( "#{@Str_param_path_dir_dodontof_server}#{@str_rbparam_filename_loginmessagefile}" , "#{$Path_dir_working_client}#{$Filename_html_loginmessage_client}" )      
        ftp.close
      end
    end
    logging("END   : #{self.class.to_s}::#{__method__.to_s}" ,$debug)
  end
    
    


  # 情報連携ファイル作成
  def MakeStatuslinkYml
    logging("START : #{self.class.to_s}::#{__method__.to_s}" ,$debug)
    if $str_param_proto_flg == $Str_param_protocol_value_ssh then
      File.open("#{$Path_dir_working_client}working.yml" , "w:#{$Str_encoding_utf8}" ) do|f|
        f.puts "#{$Str_statuslink_varname_dir_working}: #{@path_dir_working_server}" 
        f.puts "#{$Str_statuslink_varname_filename_loginmessage}: #{@str_rbparam_filename_loginmessagefile}"
        f.puts "#{$Str_statuslink_varname_status}: #{$Str_updatestatus_yet}"
        f.close
      end
    elsif $str_param_proto_flg == $Str_param_protocol_value_ftp then
      File.open("#{$Path_dir_working_client}working.yml" , "w:#{$Str_encoding_utf8}" ) do|f|
        f.puts "#{$Str_statuslink_varname_filename_loginmessage}: #{@str_rbparam_filename_loginmessagefile}"
        f.puts "#{$Str_statuslink_varname_status}: #{$Str_updatestatus_yet}"
        f.close
      end
    end
    logging("END   : #{self.class.to_s}::#{__method__.to_s}" ,$debug)
  end




  # コンフィグファイル修正
  def MakeConf
    logging("START : #{self.class.to_s}::#{__method__.to_s}" ,$info)
  
    # 新バージョンファイルをリネーム
    File.rename( "#{$Path_dir_working_client}#{$Filename_rb_config_newver_client}" , "#{$Path_dir_working_client}#{$Filename_rb_config_existing_backup}" )
  
    # oldファイルの情報を取得
    old_params = [] 
    open( "#{$Path_dir_working_client}#{$Filename_rb_config_existing_client}" , "r:#{$Str_encoding_utf8}" ) { |file|
      # 変更対象変数列を取得(version関連、diceBotOrder以外）
      old_params = file.readlines.select{|elem| /^\$.*/ =~ elem and /^\$versionOnly|^\$versionDate|^\$version|^\$diceBotOrder/ !~ elem}
    }

    # newファイルとoldファイルをマージ
    base_str = ""
    open( "#{$Path_dir_working_client}#{$Filename_rb_config_existing_backup}" , "r+b:#{$Str_encoding_utf8}" ) { |file|
      while l = file.gets
        flg = true
        old_params.each do |old_param|
          if l.split("=")[0] == old_param.split("=")[0] then
            base_str << old_param
            flg = false
          end
        end
        if flg
          base_str << l
        end
      end
    }

    # 新newバージョンファイル作成
    open( "#{$Path_dir_working_client}#{$Filename_rb_config_newver_client}" , "w+b:#{$Str_encoding_utf8}" ) {|file|
      file.write(base_str)
    }

    logging("END   : #{self.class.to_s}::#{__method__.to_s}" ,$info)
  end

  

  ######################### UPDATE #########################

  # バージョンアップ作業
  def Update
    logging("START : #{self.class.to_s}::#{__method__.to_s}" ,$info)

    
    # 連携情報取得
    self.PerseStatuslink
    
    # 新バージョンフォルダ構成取得
    self.GetNewverDirTree
    

    # 新環境構築
    self.BuildNewVer    
    
    # 情報連携ファイル作成（一応）
    self.MakeStatuslinkYml_post
    

    # 連携用ローカルフォルダ削除
    rmdir_all($Path_dir_working_client)

    logging("END   : #{self.class.to_s}::#{__method__.to_s}" ,$info)
  end

    
  ######################### VER_UP_METHOD #########################
    
  # 連携情報取得
  def PerseStatuslink
    logging("START : #{self.class.to_s}::#{__method__.to_s}" ,$debug)
    status_params = YAML.load_file($Path_yml_statuslink_clinet)
    if $str_param_proto_flg == $Str_param_protocol_value_ssh then
      # 連携ディレクトリ名取得
      $srv_working_dir = status_params[$Str_statuslink_varname_dir_working]    
    elsif $str_param_proto_flg == $Str_param_protocol_value_ftp then
      # なし
    end
    # ログインメッセージファイル名取得
    $str_statuslink_filename_html_loginmessage = status_params[$Str_statuslink_varname_filename_loginmessage]
    logging("END   : #{self.class.to_s}::#{__method__.to_s}" ,$debug)
  end



  # 新バージョンフォルダ構成取得
  def GetNewverDirTree
    logging("START : #{self.class.to_s}::#{__method__.to_s}" ,$debug)
    if $str_param_proto_flg == $Str_param_protocol_value_ssh then
      # 無し
    elsif $str_param_proto_flg == $Str_param_protocol_value_ftp then
      @List_path_files_dodontof_new_ver = []
      @List_path_dirs_dodontof_new_ver = []
  
      # 新バージョンのディレクトリ／ファイルリストを取得
      Dir.chdir( "#{$Path_dir_zipexpand_client}#{$Path_dir_dodontof_default}" )
      Find.find("./") do |f|
        if File.directory?(f) then
          @List_path_dirs_dodontof_new_ver <<   f unless f == "./"
        else
          logging("DirName  : #{File.dirname(f)}" , $debug)
          logging("FileName : #{File.basename(f)}" , $debug)
          @List_path_files_dodontof_new_ver << {:dir_name =>  File.dirname(f),:file_name => File.basename(f)}
        end
      end
    end
    logging("END   : #{self.class.to_s}::#{__method__.to_s}" ,$debug)
  end
    


  # 新環境構築
  def BuildNewVer
    logging("START : #{self.class.to_s}::#{__method__.to_s}" ,$debug)
    if $str_param_proto_flg == $Str_param_protocol_value_ssh then

      # SCP接続（新コンフィグ・ログインメッセージを作業フォルダに送信）
      Net::SCP.start($Str_param_host, $Str_param_ssh_user, :password => $Str_param_ssh_pass) do|scp|
        channel = scp.upload( "#{$Path_dir_working_client}#{$Filename_rb_config_newver_client}" , "#{$srv_working_dir}#{$Path_dir_newver_from_backup_base}#{$Filename_rb_config_default}" )
        channel.wait
        channel = scp.upload( "#{$Path_dir_working_client}#{$Filename_html_loginmessage_client}" , "#{$srv_working_dir}newver/#{$str_statuslink_filename_html_loginmessage}" )
        channel.wait
      end
      
      # SSH接続（新環境の配置）
      Net::SSH.start($Str_param_host, $Str_param_ssh_user, :password => $Str_param_ssh_pass) do |ssh|
        invoke(ssh, "#{@Cmd_cp_fixed} #{$srv_working_dir}newver/#{$Path_dir_dodontof_default}* #{@Str_param_path_dir_dodontof_server}" )
        invoke(ssh, "#{@Cmd_cp_fixed} #{$srv_working_dir}newver/config.rb #{@Str_param_path_dir_dodontof_server}#{$Path_rb_config_from_dodontof_dir}" )
        invoke(ssh, "#{@Cmd_cp_fixed} #{$srv_working_dir}newver/#{$str_statuslink_filename_html_loginmessage} #{@Str_param_path_dir_dodontof_server}#{$str_statuslink_filename_html_loginmessage}" )
      end
    elsif $str_param_proto_flg == $Str_param_protocol_value_ftp then
      # 追加ディレクトリ作成、ファイル送信
      if nil == ENV[$Str_env_path_exefile_ocra] then 
        Dir.chdir(File.dirname(__FILE__))
      else
        Dir.chdir(File.dirname(ENV[$Str_env_path_exefile_ocra]))
      end
      Net::FTP.open($Str_param_host,$Str_param_ftp_user,$Str_param_ftp_pass) do |ftp|
        ftp.passive = true
        ftp.binary = true

        # ディレクトリが存在しない場合に作成
        @List_path_dirs_dodontof_new_ver.each do|dir|
          path_dir_target_make_newver = correct_dir(dir.gsub(/^\./, @Str_param_path_dir_dodontof_server ))
          begin
            ftp.mkdir(path_dir_target_make_newver)
          rescue
            logging("this Dir is already exists! : #{path_dir_target_make_newver}",$debug)
          end
        end
        # 新規ファイル送信（上書き）
        @List_path_files_dodontof_new_ver.each do |file|  
          path_file_src_put_newver = correct_dir( "#{$Path_dir_zipexpand_client}#{file[:dir_name].gsub(/^\./,$Path_dir_dodontof_default)}/#{file[:file_name]}")
          path_file_dst_put_newver = correct_dir( "#{file[:dir_name].gsub(/^\./,@Str_param_path_dir_dodontof_server)}/#{file[:file_name]}")
          logging("ftp_src_file : #{path_file_src_put_newver}" , $debug)
          logging(" ->ftp_dst_file : #{path_file_dst_put_newver}" , $debug)
          ftp.put( File::expand_path(path_file_src_put_newver) ,  path_file_dst_put_newver)
        end
        
        # 新規コンフィグ送信
        ftp.puttextfile( "#{$Path_dir_working_client}#{$Filename_rb_config_newver_client}" , "#{@Str_param_path_dir_dodontof_server}#{$Path_rb_config_from_dodontof_dir}" )
        # ログインメッセージ引き継ぎ
        ftp.puttextfile( "#{$Path_dir_working_client}#{$Filename_html_loginmessage_client}" , "#{@Str_param_path_dir_dodontof_server}#{$str_statuslink_filename_html_loginmessage}" )
        ftp.close
      end
    end
    logging("END   : #{self.class.to_s}::#{__method__.to_s}" ,$debug)
  end
    
  # 情報連携ファイル作成（一応）
  def MakeStatuslinkYml_post
    logging("START : #{self.class.to_s}::#{__method__.to_s}" ,$debug)
    open("#{$Path_dir_working_client}working.yml" , "w:#{$Str_encoding_utf8}" ) do|file|
      file.write("status: already")
    end
    logging("END   : #{self.class.to_s}::#{__method__.to_s}" ,$debug)
  end
    
end
