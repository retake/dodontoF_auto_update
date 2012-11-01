#! ruby -Ku
# -*- encoding: utf-8 -*-



# ログ定数
$info = "info"
$debug = "debug"
$warn = "warn"
$error = "error"


# 環境定数
$Filename_rb_config_default = 'config.rb'
$Path_dir_dodontof_default = 'DodontoF_WebSet/public_html/DodontoF/'
$Path_rb_config_from_dodontof_dir = "src_ruby/#{$Filename_rb_config_default}"
$Path_dir_working_client = './working/'
$Path_dir_zipexpand_client = "#{$Path_dir_working_client}zip/"
$Path_yml_param_client = './params.yml'
$Path_yml_statuslink_clinet = "#{$Path_dir_working_client}working.yml"
$Str_updatestatus_yet = "yet"
$Str_updatestatus_already = "already"

$Filename_rb_config_existing_client = '01_old_config.rb'
$Filename_rb_config_newver_client = '01_new_config.rb'
$Filename_rb_config_existing_backup = "#{$Filename_rb_config_default}.bak"

$Filename_html_loginmessage_client = '02_new_login_message.html'


$Path_dir_backup_from_backup_base = 'backup/'
$Path_dir_newver_from_backup_base = 'newver/'

$Filename_tar_backup_dodontof = 'dodontoF.tar'
$Filename_tar_backup_imageuploadspace = 'img.tar'
$Filename_tar_backup_save = 'save.tar'


# コマンドライン定数
$Cmd_mkdir = 'mkdir -p'
$Cmd_tar_comp = 'tar -cf'
$Cmd_zip_exp = 'unzip -d'
$Cmd_cp = 'cp -rf'
$Cmd_date = 'date +%Y_%m%d_%H%M%S'
$Cmd_cd = 'cd'
$Cmd_pwd = 'pwd'
$Cmd_wget = 'wget'


# 文字コード
$Str_encoding_utf8 = 'utf-8'


# OCRA用定数
$Str_env_path_exefile_ocra = 'OCRA_EXECUTABLE'


# params定数
$Str_varname_param_full_auto_flg = 'full_auto_flg'
$Flg_param_full_auto_flg_auto = 1
$Flg_param_full_auto_flg_manual = 0
$Str_varname_param_host = 'host'
$Str_varname_param_protocol = 'proto'
$Str_param_protocol_value_ssh = 'ssh'
$Str_param_protocol_value_ftp = 'ftp'
$Str_varname_param_ssh_user = 'ssh_user'
$Str_varname_param_ssh_password = 'ssh_pass'
$Str_varname_param_sudo_flg = 'sudo_flg'
$Flg_param_sudo_flg_use = 1
$Flg_param_sudo_flg_nouse = 0
$Str_varname_param_sudo_password = 'sudo_pass'
$Str_varname_param_ftp_user = 'ftp_user'
$Str_varname_param_ftp_password = 'ftp_pass'
$Str_varname_param_work_dir = 'work_dir'
$Str_varname_param_ddtf_dir = 'ddtf_dir'

# statuslink定数
$Str_statuslink_varname_dir_working = 'srv_working_dir'
$Str_statuslink_varname_filename_loginmessage = 'login_message_file'
$Str_statuslink_varname_status = 'status'


# どどんとふ最新版表示URL
$Uri_base_dodontof_newver = 'http://www.dodontof.com/DodontoF/'
$Uri_html_dodontof_newver_from_base = "newestVersion.html"


# どどんとふコンフィグ解析用定数
$Str_varname_rb_config_loginmessagefile = 'login_message_file'
$Str_varname_rb_config_imagedirpath = 'img_dir_path'
$Str_varname_rb_config_savedirpath = 'save_dir_path'




