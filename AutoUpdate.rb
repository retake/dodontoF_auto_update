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
    



# 初期化
params = YAML.load_file("./params.yml")

# オートフラグ
auto_flg = params["full_auto_flg"]
# 連携有無
status = ""
status =  YAML.load_file("#{$Client_work_dir}working.yml")["status"] if File.exist?( "#{$Client_work_dir}working.yml" )

if auto_flg == 1 or status == "already" then
  if nil==ARGV[0] then
    print "新しいどどんとふのzipを指定して下さい"
    exit
  end
end

main_proc = Main::new(params)


# バージョンアップ
begin

  # 全自動時
  if  auto_flg == 1 then
    main_proc.pre_ver_up
    main_proc.ver_up
  # 手動修正時
  elsif auto_flg == 0
    # アップデート準備
    if status == "" or status == "already" then 
      main_proc.pre_ver_up
    # アップデート実行
    elsif auto_flg == 0 and status == "yet" then
      main_proc.ver_up
    end
  end
  
rescue => e
  logging(e,"info")
end




