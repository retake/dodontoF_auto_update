#! ruby -Ku
# -*- encoding: utf-8 -*-


# oldファイルの情報を取得
old_params = [] 
open( "./working/01_old_config.rb" , "r:utf-8" ) { |file|
  # 変更対象変数列を取得(version関連、diceBotOrder以外）
  old_params = file.readlines.select{|elem| /^\$.*/ =~ elem and /^\$versionOnly|^\$versionDate|^\$version|^\$diceBotOrder/ !~ elem}
}

# newファイルとoldファイルをマージ
base_str = ""
open( "./working/01_new_config.rb.bak" , "r+b:utf-8" ) { |file|
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
