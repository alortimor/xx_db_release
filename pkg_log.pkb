create or replace body pkg_log as

  function get_env (p_db_name in varchar2) return release_env_db%rowtype as
    r_eb release_env_db%rowtype;
     begin
       select * into r_eb
       from release_env_db
       where db_name = p_db_name;
       return r_eb;
       exception
          when no_data_found then
            return null;
  end get_env;

  procedure log_deploy_create(p_db_name         in varchar2
                             ,p_svn_url         in varchar2 default null
                             ,p_revision_number in pls_integer
                             ,p_log_file_name   in varachar2
                             ,p_schema_list     in varchar2
                             ,p_pre_cnt         in varchar2
                             ,p_unix_account    in varchar2
                             ,p_deploy_id       out number) as

    r_eb            release_env_db%rowtype := get_env(p_db_name);
    l_deploy_id     number := sq_deploy.nextval;
    l_sql           varchar2(10000);
    l_svn_release   release_deploy.svn_release%type := substr(p_svn_url
                                                             ,instr(p_svn_url, 'Tags' + 5
                                                             ,instr(p_svn_url) - (instr(p_svn_url, 'Tags')+5)) ;

    l_svn_comp      varchar2(40) := substr(p_svn_url
                                          ,instr(p_svn_url, 'first' + 6
                                          ,instr(p_svn_url, '/Tags') - (instr(p_svn_url, 'first') + 6 );

    begin
       insert into release_deploy (deploy_id
                                  ,deploy_date
                                  ,env_name
                                  ,db_name
                                  ,unix_account
                                  ,sys_component
                                  ,svn_component
                                  ,svn_rev_number
                                  ,svn_full_path
                                  ,pre_invalid_cnt
                                  ,log_file_name
                                  ,schema_list)
                       values     (sq_deploy.nextval
                                  ,sysdate
                                  ,r_eb.env_name
                                  ,r_eb.db_name
                                  ,p_unix_account
                                  ,r_eb.sys_component
                                  ,l_svn_comp
                                  ,l_svn_release
                                  ,p_revision_number
                                  ,p_svn_url
                                  ,p_pre_cnt
                                  ,p_log_file_name
                                  ,p_schema_list)
       return deploy_id into l_deploy_id;

       commit;
       p_depoy_id := l_deploy_id;
   
      
  end log_deploy_create;

  procedure log_action_create(p_deploy_id    in number
                             ,p_release_item in varchar2) as
    pragma autonomous_transaction;
    begin
      insert into release_action (deploy_id
                                 ,release_item
                                 ,start_time
                       values   ( p_deploy_id
                                 ,p_release_item
                                 ,current_timestamp);
      commit;
  end log_action_create;
  
  procedure log_action_update (p_deploy_id      in number
                              ,p_release_item   in varchar2
                              ,p_execute_output in varchar2) as
    pragma autonomous_transaction;
    begin
      update release_action set execute_output = execute_output || p_execute_output
                               ,exception_count= nvl(exception_count,0)+regexp_count (p_execute_output, '.*ORA-|SP2|PLS.*')
                               ,end_time       = current_timestamp
      where  deploy_id    = p_deploy_id
      and    release_item = p_release_item;
      commit;
  end log_action_update;

  procedure log_deploy_update_final(p_deploy_id in number, p_post_cnt in pls_integer) as
    l_schema_list  release_deploy.schema_list%type;
    pragma autonomous_transaction;
    begin
      select schema_list into l_schema_list
      from release_deploy where deploy_id = p_deploy_id;

      update release_deploy rd set exception_count = (select sum(ra.exception_count)
                                                      from   release_action ra where ra.deploy_id=rd.deploy_id)
                                  ,post_invalid_cnt = p_post_cnt
      where rd.deploy_id = p_deploy_id;
      commit;
  end log_deploy_update_final;

  procedure log_deploy_update(p_deploy_id   in number
                             ,p_log         in clob default null) as
    begin
      if (p_log is not null) then
        update release_deploy set deploy_log = deploy_log||p_log
        where deploy_id=p_deploy_id;
      end if;
      commit;
  end log_deploy_update;

end pkg_log;
/
show error

