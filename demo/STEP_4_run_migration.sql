BEGIN
   migration_run_framework.launch(i_batch                        => 1
                                 ,i_migration_group              => 'DEMO'
                                 ,i_context                      => 'DEMO'
                                 ,i_start_at_step                => 1
                                 ,i_concurrency                  => 8
                                 ,i_max_rows_per_thread          => 500
                                 ,i_suppress_emails_bool         => TRUE
                                 ,i_halt_on_error_bool           => TRUE
                                 ,i_master_monitors_monitor_bool => TRUE
                                 ,i_external_context_controller  => 'TRUNC_TARGET=TRUE;JOB=SALESMAN');
END;
/