#! ruby -Ku
# -*- encoding: utf-8 -*-

require 'zip/zipfilesystem'
require 'fileutils'
require 'logger'
require 'stricts'

$log = Logger.new(STDOUT)
$log.level = Logger::INFO


# ディレクトリパスの末尾の"/"を確認
def check_dir(dir_str)
  correct_dir(dir_str + "/")
end

# パス作成時の"/"の重複を削除
def correct_dir(str)
  str.gsub(/\/\//, "/")
end

# 改行コードを削除
def delete_crlf(str)
  str.sub(/\n$|\r$|\r\n$/,"")
end


# 命令をsudo形式にして返す
def make_sudo(pass,com)
  "yes \'#{pass}\' | sudo -S #{com}"
end


# コマンド実行する
def invoke(ssh,command)
  response = ''
  ssh.exec!(command) do |channel, stream,data|
    if stream == :stdout
      logging(data,$debug)
      response += data
    elsif stream == :stderr
      logging(data,$debug)
    end
  end
  response
end

# コマンド実行する(標準出力を返さない）
def invoke_nomsg(ssh,command)
  ssh.exec!(command) do |channel, stream,data|
    if stream == :stdout
      logging(data,$debug)
    elsif stream == :stderr
      logging(data,$debug)
    end
  end
end


# zip解凍
def ore_unzip(src_path, output_path)
  output_path = (output_path + "/").sub("//", "/")
  Zip::ZipInputStream.open(src_path) do |s|
    while f = s.get_next_entry()
      d = File.dirname(f.name)
      FileUtils.makedirs(output_path + d)
      f =  output_path + f.name
      unless f.match(/\/$/)
        logging(f,$debug)
        File.open(f, "w+b") do |wf|
          wf.puts(s.read())
        end
      end
    end
  end
end


# ログ出力
def logging(str,level)
  case level
  when $info
    $log.info(str)
  when $warn
    $log.warn(str)
  when $debug
    $log.debug(str)
  when $error
    $log.error(str)
  end
end



# rbから直にテキストで取得時の文字列トリム
def trim_rbstr(str)
  str.gsub(/ |\"|\'|\r\n|\r|\n/,"")
end




# 中身が空ではないディレクトリを削除
def rmdir_all(dst_dir)

  # サブディレクトリを階層が深い順にソートした配列を作成
  dirlist = Dir::glob(dst_dir + "**/").sort {
    |a,b| b.split('/').size <=> a.split('/').size
  }

  # サブディレクトリ配下の全ファイルを削除後、サブディレクトリを削除
  dirlist.each {|d|
    Dir::foreach(d) {|f|
      File::delete(d+f) if ! (/\.+$/ =~ f)
    }
    Dir::rmdir(d)
  }

end



