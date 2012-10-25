#! ruby -Ku
# -*- encoding: utf-8 -*-


# ライブラリ等指定
$LOAD_PATH << File.dirname(__FILE__)
require 'Main'
require 'baselibs'


# バージョンアップ実行
begin
  Main::new.ver_up
rescue => e
  logging(e,"info")
end


