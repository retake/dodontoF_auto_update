#! ruby -Ku
# -*- encoding: utf-8 -*-


# ライブラリ等指定
$LOAD_PATH << File.dirname(__FILE__)
require 'Main'
require 'baselibs'


if nil==ARGV[0] then
  print "新しいどどんとふのzipを指定して下さい"
  exit
end

main_proc = Main::new

# バージョンアップ前処理実行
begin
  main_proc.pre_ver_up
  main_proc.make_conf
rescue => e
  logging(e,"info")
end


