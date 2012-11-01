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
if nil == ENV[$Str_env_path_exefile_ocra] then 
  Dir.chdir(File.dirname(__FILE__))
else
  Dir.chdir(File.dirname(ENV[$Str_env_path_exefile_ocra]))
end
    



# 初期化
params = YAML.load_file( $Path_yml_param_client )

# オートフラグ
auto_flg = params[$Str_varname_param_full_auto_flg]
# 連携有無
status = ""
status =  YAML.load_file( $Path_yml_statuslink_clinet )["status"] if File.exist?( $Path_yml_statuslink_clinet )

if auto_flg == $Flg_param_full_auto_flg_auto or status == $Str_updatestatus_already then
  if nil==ARGV[0] then
 #   print "新しいどどんとふのzipを指定して下さい"
 #   exit
  end
end

main_proc = Main::new(params)


# バージョンアップ
begin

  # 全自動時
  if  auto_flg == $Flg_param_full_auto_flg_auto then
    main_proc.PreUpdate
    main_proc.Update
  # 手動修正時
  elsif auto_flg == $Flg_param_full_auto_flg_manual
    # アップデート準備
    if status == "" or status == $Str_updatestatus_already then 
      main_proc.PreUpdate
    # アップデート実行
    elsif auto_flg == $Flg_param_full_auto_flg_manual and status == $Str_updatestatus_yet then
      main_proc.Update
    end
  end
  
rescue => e
  logging(e,"info")
end




