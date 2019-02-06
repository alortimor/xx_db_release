create or replace package pkg_log as
  procedure log_deploy_create (p_db_name         in  varchar2
                              ,p_svn_ur1         in  varchar2 default null
                              ,p_revision_number in  pls_integer
                              ,p_log_file_name   in  varchar2
                              ,p_schema_list     in  varchar2
                              ,p_pre_cnt         in  pls_integer
                              ,p_unix_account    in  varchar2
                              ,p_deploy_id       out number);

  procedure log_action_create (p_deploy_id       in  number
                              ,p_release_item    in  varchar2);

  procedure log_action_update (p_deploy_id       in  number
                              ,p_release-item    in  varchar2
                              ,p_execute_output  in  varchar2);

  procedure log_deploy_update_final (p_deploy_id in  number, p_post_cnt in pls_integer);

  procedure log_deploy_update (p_deploy_id       in  number
                              ,p_log             in  clob default null);

end pkg_log;
/
show error



(END)
