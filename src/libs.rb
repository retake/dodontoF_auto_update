#! ruby -Ku
# -*- encoding: utf-8 -*-

require 'baselibs'
require 'fileutils'
require 'find'


# config現情報解析
def parse_rbconf(conf_file)
  result = {}
  open( conf_file , "r:utf-8" ) { |file|
    lines = file.readlines
    # ログインメッセージバックアップ
    result['login_message_file']  = trim_rbstr(lines.find{|elem| /^\$loginMessageFile.*/ =~ elem}.split("=")[1])

    # imageUploadSpaceバックアップ
    result['img_dir_path'] = trim_rbstr(lines.find{|elem| /^\$imageUploadDir.*/ =~ elem}.split("=")[1])

    # saveDataバックアップ
    result['save_dir_path'] = trim_rbstr(lines.find{|elem| /^\$SAVE_DATA_DIR.*/ =~ elem}.split("=")[1])
  }
  
  result
end




