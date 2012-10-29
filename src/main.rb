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


  # 初期処理
  def initialize(params)
    logging("START : #{self.class.to_s}::#{__method__.to_s}" ,$info)

    # パラメータ設定
    $host = params["host"]
    $proto = params["proto"]
    $ssh_user = params["ssh_user"]
    $ssh_pass = params["ssh_pass"]
    $sudo_flg = params["sudo_flg"]
    $sudo_pass = params["sudo_pass"]
    $ftp_user = params["ftp_user"]
    $ftp_pass = params["ftp_pass"]
    @Ddtf_dir_path = check_dir(params["ddtf_dir"])
    @Work_dir_path = check_dir(params["work_dir"])
    
     
    # cpコマンド修正(sudo時)
    if $sudo_flg == 1 then
      @Cp_cmd_exe = make_sudo($sudo_pass , $Cp_cmd) if $sudo_flg == 1
    elsif $sudo_flg == 0 then
      @Cp_cmd_exe = $Cp_cmd
    end
    
    
    # protoコマンド修正
    $ssh = "ssh"
    $ftp = "ftp"

    $proto_flg = ""
    case $proto.downcase
    when "ssh"
      $proto_flg = $ssh;
    when "ftp"
      $proto_flg = $ftp;
    end
    
    logging("END   : " + self.class.to_s + "::" + __method__.to_s ,$info)
  end



  # バージョンアップ前段階作業
  def pre_ver_up
    logging("START : #{self.class.to_s}::#{__method__.to_s}" ,$info)

    # どどんとふzipファイル情報取得
    #@new_ddtf_zip = File.expand_path(ARGV[0])
    


    # 共通処理(クライアント作業ディレクトリ作成）
    begin
      Dir::mkdir($Client_work_dir)
    rescue Errno::EEXIST
      logging("\"#{File.expand_path($Client_work_dir)}\" is already exists",$warn)
    end

    begin
      Dir::mkdir($Client_zip_dir) if $proto.downcase=="ftp"
    rescue Errno::EEXIST
      logging("\"#{File.expand_path($Client_zip_dir)}\" is already exists",$warn)
    end


    # どどんとふ最新版ダウンロード
    doc = Nokogiri::HTML(open('http://www.dodontof.com/DodontoF/newestVersion.html','r:utf-8').read)
    ddtf_latest_ver_nm = doc.search("a").first["href"].gsub(/^\.\//,"")
    ddtf_latest_uri =  "http://www.dodontof.com/DodontoF/#{ddtf_latest_ver_nm}"
    @new_ddtf_zip = File.expand_path("#{$Client_work_dir}#{ddtf_latest_ver_nm}")
    hc = HTTPClient.new
    f = File.open(@new_ddtf_zip, "wb")
      f.print(hc.get_content(ddtf_latest_uri))
    f.close

    # サーバ側作業フォルダ作成/バックアップ
    if $proto_flg == $ssh then
      @srv_working_dir_path = ''
      @srv_backup_dir_path = ''
      @srv_newver_dir_path = ''
      @srv_zip_path = ''

      # SSH接続（作業フォルダ作成・バックアップ）
      Net::SSH.start($host, $ssh_user, :password => $ssh_pass) do |ssh|
      
        # 今作業用フォルダを作成
        @srv_working_dir_path = check_dir(@Work_dir_path + delete_crlf(invoke(ssh , "#{$Date}")))
        invoke(ssh, "#{$Mkdir_cmd} #{@srv_working_dir_path}" ) 
        
        # バックアップ用フォルダ、新バージョン用フォルダを作成
        @srv_backup_dir_path = "#{@srv_working_dir_path}backup/"
        @srv_newver_dir_path = "#{@srv_working_dir_path}newver/"
        invoke(ssh, "#{$Mkdir_cmd} #{@srv_backup_dir_path}" )
        invoke(ssh, "#{$Mkdir_cmd} #{@srv_newver_dir_path}" )
        
        # バックアップ実行(メインディレクトリ、コンフィグ）
        invoke(ssh, "#{$Comp_tar_cmd} #{@srv_backup_dir_path}dodontoF.tar #{@Ddtf_dir_path}*" )
        invoke(ssh, "#{@Cp_cmd_exe} #{@Ddtf_dir_path}src_ruby/config.rb #{@srv_backup_dir_path}config.rb" )
      end
    elsif $proto_flg == $ftp then
      # 無し
    end

    # zipファイル展開
    if $proto_flg == $ssh then
      # SCP接続（新バージョンのzipファイルを送信）
      Net::SCP.start($host, $ssh_user, :password => $ssh_pass) do|scp|
        @srv_zip_path =  "#{@srv_newver_dir_path}#{File.basename(@new_ddtf_zip)}"
        channel = scp.upload(@new_ddtf_zip , @srv_zip_path )
        channel.wait
      end
      # SSH接続（zip解凍）
      Net::SSH.start($host, $ssh_user, :password => $ssh_pass) do |ssh|
        # zip解凍
        invoke_nomsg(ssh, "#{$Exp_zip_cmd} #{@srv_newver_dir_path} #{@srv_zip_path}" )
      end
    elsif $proto_flg == $ftp then
      # クライアントでzipを解凍
      ore_unzip(@new_ddtf_zip , $Client_zip_dir)
    end



    # 新旧コンフィグ準備
    if $proto_flg == $ssh then
      # 新旧コンフィグ取得
      Net::SCP.start($host, $ssh_user, :password => $ssh_pass) do|scp|
        channel = scp.download( "#{@srv_newver_dir_path}#{$Def_ddtf_path}#{$Conf_file_from_ddtf_path}" , "#{$Client_work_dir}01_new_config.rb" )
        channel.wait
        channel = scp.download( "#{@srv_backup_dir_path}config.rb" , "#{$Client_work_dir}01_old_config.rb" )
        channel.wait
      end
    elsif $proto_flg == $ftp then
      # 現行のコンフィグを取得
      Net::FTP.open($host, $ftp_user, $ftp_pass) do |ftp|
        ftp.passive = true
        ftp.getbinaryfile( "#{@Ddtf_dir_path}src_ruby/config.rb" , "#{$Client_work_dir}01_old_config.rb" )      
        ftp.close
      end
      # 新コンフィグの雛形をコピー
      FileUtils.copy( "#{$Client_zip_dir}#{$Def_ddtf_path}#{$Conf_file_from_ddtf_path}" , "#{$Client_work_dir}01_new_config.rb" )
    end


    # 取得したコンフィグを解析（共通）
    rbconf_params = parse_rbconf("#{$Client_work_dir}01_old_config.rb")


    # その他情報バックアップ
    if $proto_flg == $ssh then
      # SSH接続（ログインメッセージ、uploadImageSpace,saveDataバックアップ）
      Net::SSH.start($host, $ssh_user, :password => $ssh_pass) do |ssh|
        open( "#{$Client_work_dir}01_old_config.rb" , "r:#{$enc_str}" ) { |file|
          # ログインメッセージバックアップ
          invoke(ssh, "#{@Cp_cmd_exe} #{@Ddtf_dir_path}#{rbconf_params['login_message_file']} #{@srv_backup_dir_path}#{rbconf_params['login_message_file']}" )
          # imageUploadSpaceバックアップ
          invoke(ssh, "#{$Cd_cmd} #{@Ddtf_dir_path} ; #{$Comp_tar_cmd} #{@srv_backup_dir_path}img.tar #{rbconf_params['img_dir_path']}/* ")
          # saveDataバックアップ
          invoke(ssh, "#{$Cd_cmd} #{@Ddtf_dir_path} ; #{$Comp_tar_cmd} #{@srv_backup_dir_path}save.tar #{rbconf_params['save_dir_path']}/* ")
        }
      end
    elsif $proto_flg == $ftp then
      # なし
    end


    # 引き継ぎ情報取得
    if $proto_flg == $ssh then
      Net::SCP.start($host, $ssh_user, :password => $ssh_pass) do|scp|
        channel = scp.download( "#{@srv_backup_dir_path}#{rbconf_params['login_message_file']}" , "#{$Client_work_dir}01_new_login_message.html" )
        channel.wait
      end
    elsif $proto_flg == $ftp then
      Net::FTP.open($host, $ftp_user, $ftp_pass) do |ftp|
        ftp.passive = true
        ftp.gettextfile( "#{@Ddtf_dir_path}#{rbconf_params['login_message_file']}" , "#{$Client_work_dir}01_new_login_message.html" )      
        ftp.close
      end
    end

    # 情報連携ファイル作成
    if $proto_flg == $ssh then
      File.open("#{$Client_work_dir}working.yml" , "w:#{$enc_str}" ) do|f|
        f.puts "srv_working_dir: #{@srv_working_dir_path}" 
        f.puts "login_message_file: #{rbconf_params['login_message_file']}"
        f.puts "status: yet"
        f.close
      end
    elsif $proto_flg == $ftp then
      File.open("#{$Client_work_dir}working.yml" , "w:#{$enc_str}" ) do|f|
        f.puts "login_message_file: #{rbconf_params['login_message_file']}"
        f.puts "status: yet"
        f.close
      end
    end
    
    
    # コンフィグファイル差分修正
    make_conf
    


    logging("END   : #{self.class.to_s}::#{__method__.to_s}" ,$info)
  end



  # バージョンアップ作業
  def ver_up
    logging("START : #{self.class.to_s}::#{__method__.to_s}" ,$info)

    
    # 連携情報取得
    status_params = YAML.load_file("#{$Client_work_dir}working.yml")
    if $proto_flg == $ssh then
      # 連携ディレクトリ名取得
      $srv_working_dir = status_params["srv_working_dir"]    
    elsif $proto_flg == $ftp then
      # なし
    end
    # ログインメッセージファイル名取得
    $login_message_file = status_params["login_message_file"]


    # 新バージョンフォルダ構成取得
    if $proto_flg == $ssh then
      # 無し
    elsif $proto_flg == $ftp then
      @file_list = []
      @dir_list = []
  
      # 新バージョンのディレクトリ／ファイルリストを取得
      Dir.chdir( "#{$Client_zip_dir}#{$Def_ddtf_path}" )
      Find.find("./") do |f|
          if File.directory?(f)
          @dir_list <<   f unless f == "./"
        else
          logging("DirName  : #{File.dirname(f)}" , $debug)
          logging("FileName : #{File.basename(f)}" , $debug)
          @file_list << {:dir_name =>  File.dirname(f),:file_name => File.basename(f)}
        end
      end
    end


    # 新環境構築
    if $proto_flg == $ssh then

      # SCP接続（新コンフィグ・ログインメッセージを作業フォルダに送信）
      Net::SCP.start($host, $ssh_user, :password => $ssh_pass) do|scp|
        channel = scp.upload( "#{$Client_work_dir}01_new_config.rb" , "#{$srv_working_dir}newver/config.rb" )
        channel.wait
        channel = scp.upload( "#{$Client_work_dir}01_new_login_message.html" , "#{$srv_working_dir}newver/#{$login_message_file}" )
        channel.wait
      end
  
      # SSH接続（新環境の配置）
      Net::SSH.start($host, $ssh_user, :password => $ssh_pass) do |ssh|
        invoke(ssh, "#{@Cp_cmd_exe} #{$srv_working_dir}newver/#{$Def_ddtf_path}* #{@Ddtf_dir_path}" )
        invoke(ssh, "#{@Cp_cmd_exe} #{$srv_working_dir}newver/config.rb #{@Ddtf_dir_path}#{$Conf_file_from_ddtf_path}" )
        invoke(ssh, "#{@Cp_cmd_exe} #{$srv_working_dir}newver/#{$login_message_file} #{@Ddtf_dir_path}#{$login_message_file}" )

      end
    elsif $proto_flg == $ftp then
      # 追加ディレクトリ作成、ファイル送信
      if nil == ENV['OCRA_EXECUTABLE'] then 
        Dir.chdir(File.dirname(__FILE__))
      else
        Dir.chdir(File.dirname(ENV['OCRA_EXECUTABLE']))
      end
      Net::FTP.open($host,$ftp_user,$ftp_pass) do |ftp|
        ftp.passive = true
        ftp.binary = true
  
        # ディレクトリが存在しない場合に作成
        @dir_list.each do|dir|
          dir_path = correct_dir(dir.gsub(/^\./, @Ddtf_dir_path ))
          begin
            ftp.mkdir(dir_path)
          rescue
            logging("this Dir is already exists! : #{dir_path}",$debug)
          end
        end
  
        # 新規ファイル送信（上書き）
        @file_list.each do |file|  
          src_file_path = correct_dir( "#{$Client_zip_dir}#{file[:dir_name].gsub(/^\./,$Def_ddtf_path)}/#{file[:file_name]}")
          dst_file_path = correct_dir( "#{file[:dir_name].gsub(/^\./,@Ddtf_dir_path)}/#{file[:file_name]}")
          logging("ftp_src_file : #{src_file_path}" , $debug)
          logging(" ->ftp_dst_file : #{dst_file_path}" , $debug)
          ftp.put( File::expand_path(src_file_path) ,  dst_file_path)
        end
        
        # 新規コンフィグ送信
        ftp.puttextfile( "#{$Client_work_dir}01_new_config.rb" , "#{@Ddtf_dir_path}src_ruby/config.rb" )
        # ログインメッセージ引き継ぎ
        ftp.puttextfile( "#{$Client_work_dir}01_new_login_message.html" , "#{@Ddtf_dir_path}#{$login_message_file}" )
        ftp.close
      end

    end
    
    
    # 情報連携ファイル作成
    open("#{$Client_work_dir}working.yml" , "w:#{$enc_str}" ) do|file|
      file.write("status: already")
    end


    # 連携用ローカルフォルダ削除
    rmdir_all($Client_work_dir)


    logging("END   : #{self.class.to_s}::#{__method__.to_s}" ,$info)
  end







  # コンフィグファイル修正
  def make_conf
    logging("START : #{self.class.to_s}::#{__method__.to_s}" ,$info)
  
    # 新バージョンファイルをリネーム
    File.rename( "#{$Client_work_dir}01_new_config.rb" , "#{$Client_work_dir}01_new_config.rb.bak" )
  
    # oldファイルの情報を取得
    old_params = [] 
    open( "#{$Client_work_dir}01_old_config.rb" , "r:#{$enc_str}" ) { |file|
      # 変更対象変数列を取得(version関連、diceBotOrder以外）
      old_params = file.readlines.select{|elem| /^\$.*/ =~ elem and /^\$versionOnly|^\$versionDate|^\$version|^\$diceBotOrder/ !~ elem}
    }

    # newファイルとoldファイルをマージ
    base_str = ""
    open( "#{$Client_work_dir}01_new_config.rb.bak" , "r+b:#{$enc_str}" ) { |file|
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
    open( "#{$Client_work_dir}01_new_config.rb" , "w+b:#{$enc_str}" ) {|file|
      file.write(base_str)
    }

    logging("END   : #{self.class.to_s}::#{__method__.to_s}" ,$info)
  end

  


end
