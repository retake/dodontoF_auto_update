#! ruby -Ku
# -*- encoding: utf-8 -*-


# ライブラリ等指定
$LOAD_PATH << File.dirname(__FILE__)
require 'Main'
require 'baselibs'
require 'yaml'
require 'stricts'
require 'fileutils'

# カレントディレクトリを変更
if nil == ENV['OCRA_EXECUTABLE'] then 
  Dir.chdir(File.dirname(__FILE__))
else
  Dir.chdir(File.dirname(ENV['OCRA_EXECUTABLE']))
end
    


#if nil==ARGV[0] then
#  print "新しいどどんとふのzipを指定して下さい"
#  exit
#end


# 初期化
params = YAML.load_file("./params.yml")
main_proc = Main::new(params)


# バージョンアップ
begin

  # オートフラグ
  auto_flg = params["full_auto_flg"]

  # 全自動時
  if  auto_flg == 1 then
  print 
    main_proc.pre_ver_up
    main_proc.make_conf
    main_proc.ver_up
  # 手動修正時
  elsif auto_flg == 0 then
    # 連携ファイルが存在する場合
    if File.exist?( "#{$Client_work_dir}working.yml" )
      status = YAML.load_file("#{$Client_work_dir}working.yml")["status"]
      # アップデート済みの場合（前回分のごみが残ってる場合）
      if status == "already" then
        main_proc.pre_ver_up
        main_proc.make_conf
      # アップデート前の場合
      elsif status == "yet" then
        main_proc.ver_up
      end
    # 連携ファイルが存在しない場合
    else
      main_proc.pre_ver_up
      main_proc.make_conf
    end
  end
  
rescue => e
  logging(e,"info")
end




