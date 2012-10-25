#! ruby -Ku
# -*- encoding: utf-8 -*-

class ValidateCf

  # validete実行
  def exec_validate(params)
  
    begin
      self.host_check(params)
      self.proto_check(params)
      
      case params["proto"].downcase
      when "ssh"
        self.ssh_check(params)
        self.sudo_check(params)
      when "ftp"
        self.ftp_check(params)
      end
      
      
      
    rescue

    end
  end

  # ホストチェック
  def host_check(param)
    if nil == params["host"] then
      # 空欄エラー
    end
  end


  # プロトコルチェック
  def proto_check(params)
    if nil == params["proto"] then
      # 空欄エラー
    elsif /ssh|ftp/i !~ params["proto"] then
      # 指定文字列エラー
  end
  
  
  # sshチェック
  def ssh_check(params)
    if nil == params["ssh_user"] then

    end
    if nil == params["ssh_pass"] then

    end
    
    if nil == params["sudo_flg"] then
    
    end
    
    if nil == params["sudo_flg"] then
      params["sudo_flg"] = ""
    end
    
  end


  # ftpチェック
  def ftp_check(params)
    if nil == params["ftp_user"] then

    end
    if nil == params["ftp_pass"] then

    end
  end
  

  
  # ddtfディレクトリチェック
  def ddtf_dir_check(params)
    if nil == params["ddtf_dir"] then
    
    end
  end
  
  
  # 作業用ディレクトリチェック
  def work_dir_check
      if nil == params["work_dir"] then
    
    end
  end
  




end