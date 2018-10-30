BEGIN
   migration_run_framework.kill_launcher(i_killer            => 'QUEEN'
                                        ,i_skip_monitor_bool => FALSE);
END;
/

exit