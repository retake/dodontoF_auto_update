#! ruby -Ku
# -*- encoding: utf-8 -*-


# ライブラリ等指定
$LOAD_PATH << File.dirname(__FILE__)
require 'Main'
require 'libs'


if nil==ARGV[0] then
  print "新しいどどんとふのzipを指定して下さい"
  exit
end


main_proc = Main::new


# バージョンアップ
begin
  main_proc.pre_ver_up
  main_proc.make_conf
  main_proc.ver_up
rescue => e
  logging(e,"info")
end

