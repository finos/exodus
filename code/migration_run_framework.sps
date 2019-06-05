CREATE OR REPLACE PACKAGE migration_run_framework AUTHID CURRENT_USER IS

   /*=================================================================================================
       Supporting Package For ETL / Migration Utilities For Tabular to Tabular+JSON migration.
       
       Developed by Christian Leigh

       Copyright 2018 IHS Markit

       Licensed under the Apache License, Version 2.0 (the "License");
       you may not use this file except in compliance with the License.
       You may obtain a copy of the License at

           http://www.apache.org/licenses/LICENSE-2.0

       Unless required by applicable law or agreed to in writing, software
       distributed under the License is distributed on an "AS IS" BASIS,
       WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
       See the License for the specific language governing permissions and
       limitations under the License.

     =================================================================================================  
   */
   
   /*------------------------------------------------------------------------------------
   ** HELPER function (could be a computed property): returns 'INFO'
   */
   FUNCTION fn_info RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** HELPER function (could be a computed property): returns 'WARNING'
   */
   FUNCTION fn_warning RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** HELPER function (could be a computed property): returns 'WARNING'
   */
   FUNCTION fn_error RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** HELPER function (could be a computed property): returns 'STATUS'
   */
   FUNCTION fn_status RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** HELPER function (could be a computed property): returns 'MGCTX_MIGRATION_BATCH'
   */
   FUNCTION fn_ctx_migration_batch RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** HELPER function (could be a computed property): returns 'MGCTX_MIGRATION_GROUP'
   */
   FUNCTION fn_ctx_migration_group RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** HELPER function (could be a computed property): returns 'MGCTX_RUN_CONTEXT'
   */
   FUNCTION fn_ctx_run_context RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** HELPER function (could be a computed property): returns 'MGCTX_ROWS_PER_THREAD'
   */
   FUNCTION fn_ctx_rows_per_thread RETURN VARCHAR2
      PARALLEL_ENABLE;

   /*------------------------------------------------------------------------------------
   ** HELPER function (could be a computed property): returns 'MGCTX_STEP_NAME'
   */
   FUNCTION fn_ctx_step_name RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** HELPER function (could be a computed property): returns 'MGCTX_CONCURRENCY'
   */
   FUNCTION fn_ctx_concurrency RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** HELPER function (could be a computed property): returns 'MGCTX_TASK_LIST'
   */
   FUNCTION fn_ctx_task_list RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** HELPER function (could be a computed property): returns 'MGCTX_EXIT_STATE'
   */
   FUNCTION fn_ctx_exit_state RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** HELPER function (could be a computed property): returns 1000
   */
   FUNCTION fn_max_lines RETURN NUMBER;

   /*------------------------------------------------------------------------------------
   ** HELPER function. Checks if the context is a valid name.
   **
   ** @param i_context          A context name.   
   **
   ** @return                   Boolean TRUE or FALSE.  TRUE if the context is valid.
   */
   FUNCTION fn_is_valid_context(i_context IN VARCHAR2) RETURN BOOLEAN;

   /*------------------------------------------------------------------------------------
   ** Returns the number of ROWS in the OED for the given schema/table.
   **
   ** @param i_schema_name       The schema name of the table being driven with OED.
   **
   ** @param i_table_name        The table name being driven by the OED.
   **
   ** @return                    The number of rows in the OED.
   **                            (O)n (E)TL (D)river table.
   */

   FUNCTION fn_get_oed_count
   (
      i_schema_name IN VARCHAR2
     ,i_table_name  IN VARCHAR2
   ) RETURN NUMBER result_cache;
   
   /*------------------------------------------------------------------------------------
   ** Returns the exit status of the migration
   **
   ** @return                    SUCCESS / FAILED / KILLED / UNKNOWN
   */

   FUNCTION fn_get_exit_status
    RETURN VARCHAR2;   

   /*------------------------------------------------------------------------------------
   ** Register a parallel execute task.
   ** Tasks launched as dbms_parallel_execute from a migration step need to be registered.
   ** This is required so that any kill issued will ONLY seek to kill tasks from the 
   ** migration.  We don't want any embarrassing overlaps where we kill stuff we shouldn't.
   **
   ** @param i_task_name                    The task name being launched by a step.
   **
   */
   PROCEDURE pr_register_parallel_task(i_task_name IN VARCHAR2);

   /*------------------------------------------------------------------------------------
   ** De-Register a parallel execute task.
   ** When as task comes to an end it ought to be de-registered.
   **
   ** @param i_task_name                    The task name being launched by a step.
   **
   */
   PROCEDURE pr_deregister_parallel_task(i_task_name IN VARCHAR2);

   /*------------------------------------------------------------------------------------
   ** Launch a managed job.  These are single user scheduler jobs launched from  
   ** handcrafted migration steps.  Launching them through here means that we can
   ** track the job and have a way of stopping the job (if necessary through a kill).
   **
   ** @param i_job_name                    The name of the job.
   **
   ** @param i_job_sql                     An anonymous code block.
   **
   */
   PROCEDURE pr_start_managed_job
   (
      i_job_name IN VARCHAR2
     ,i_job_sql  IN VARCHAR2
   );

   /*------------------------------------------------------------------------------------
   ** Wait until the specified job has ended.  It doesn't mean that it has succeeded, it
   ** just means the job has completed.
   **
   ** @param i_job_name                   Checks a single job (or ALL jobs if not supplied).
   **
   ** @param i_check_freq_secs            Time between checks in seconds.
   **
   ** @param i_timeout_secs               Timeout in seconds.
   **
   ** @param o_status                     OUT BOUND PARAM : COMPLETE, TIMEDOUT                        
   **
   */
   PROCEDURE pr_wait_until_ended
   (
      i_job_name        IN VARCHAR2 DEFAULT 'ALL'
     ,i_check_freq_secs IN NUMBER DEFAULT 10
     ,i_timeout_secs    IN NUMBER DEFAULT 86400
     ,o_status          OUT VARCHAR2
   );

   /*------------------------------------------------------------------------------------
   ** Register a managed job.
   **
   ** @param i_job_name                   The managed job being launched.
   **
   */
   PROCEDURE pr_register_managed_job(i_job_name IN VARCHAR2);

   /*------------------------------------------------------------------------------------
   ** De-Register a managed job.
   **
   ** @param i_job_name                   The managed job that is ending.
   **
   */
   PROCEDURE pr_deregister_managed_job(i_job_name IN VARCHAR2);

   /*------------------------------------------------------------------------------------
   ** This can be called to force a status update email.
   ** Typical use for this is at the end of a big processing step.
   */
   PROCEDURE pr_force_a_status_email;

   /*------------------------------------------------------------------------------------
   ** Common logging for the migration.  
   **
   ** EG :  pr_log(i_log_type  => fn_warning
   **             ,i_log_entry => 'Something is wrong, but I can get by (for now).');
   **
   ** @param i_log_type                      Common types: fn_info / fn_status / fn_warning / fn_error
   **
   ** @param i_log_entry                     The text of the message.
   **
   ** @param i_log_batch                     The Batch ID : Can be supplied (defaults to the migration being run).
   **
   ** @param i_log_migation_group            The migration group : Defaults to the migration being run.
   **
   ** @param i_log_activity_group            The activity group : Defaults to the step being run.
   **
   ** @param i_log_extended_info             More detailed text for diagnostics.
   */

   PROCEDURE pr_log
   (
      i_log_type           IN VARCHAR2
     ,i_log_entry          IN VARCHAR2
     ,i_log_batch          IN NUMBER DEFAULT to_number(pkg_pre_etl_tools.fn_get_context_value(i_attr => fn_ctx_migration_batch))
     ,i_log_migation_group IN VARCHAR2 DEFAULT pkg_pre_etl_tools.fn_get_context_value(i_attr => fn_ctx_migration_group)
     ,i_log_activity_group IN VARCHAR2 DEFAULT pkg_pre_etl_tools.fn_get_context_value(i_attr => fn_ctx_step_name)
     ,i_log_extended_info  IN CLOB DEFAULT NULL
   );

   /*------------------------------------------------------------------------------------
   ** Sets the consumer group : dbms_resource_manager.switch_consumer_group_for_sess
   ** Based on the parameter in on_etl_params.
   */
   PROCEDURE pr_set_consumer_group;

   /*------------------------------------------------------------------------------------
   ** Issues an asychronous request to clean up the procedure generated by the migration.
   **
   ** @param i_procedure_name                The procedure to clean away.
   **  
   */
   PROCEDURE pr_cleanup_request(i_procedure_name IN VARCHAR2);

   /*------------------------------------------------------------------------------------
   ** Launch the batch.
   **
   ** @param i_batch                        The batch number to run.
   **                                       This is the batch of staging rows you want to 
   **                                       import.
   **
   ** @param i_migration_group              The migration group you want to run.
   **
   ** @param i_exception_group              The group you want to run if it all goes wrong.
   **                                       Only valid if 
   **
   ** @param i_context                      Migrations need to run under a context.
   **                                       Contexts are a way of configuring a migration
   **                                       so that the behave differently (typically write to
   **                                       other schemas).
   **                                       Contexts are used in conjunction with substitution
   **                                       vaues.. Subtitution values are set as ${value}
   **                                       so they are a good way of setting schema names. 
   ** 
   ** @param i_always_run_steps_comma_sep   This is useful if the migration has specific initialisation that 
   **                                       should run EVEN IF you are starting from a later step.
   **                                       For example contexts that need to be setup.
   **                                       If this is NULL then no steps will be run before starting at 
   **                                       i_start_at_step.
   **                                       
   ** @param i_start_at_step                Start at this specified step in the migration group.
   **                                       The default is 1 (i.e. the beginning).
   **
   ** @param i_start_at_thread              Under certain circumstances you might want to restart the 
   **                                       migration from a specific thread within a step.
   **
   ** @param i_stop_at_step                 Stop at this step.  NULL = run till end.
   **
   ** @param i_concurrency                  The maximum concurrency (only applies to steps that use
   **                                       the driver table ON_ETL_DRIVER) - Default is 10
   **                                       If a step doesn't use the ON_ETL_DRIVER then this has no effect.
   **
   ** @param i_max_rows_per_thread          This is a target value (sometimes a worker thread might be a little 
   **                                       above or below this value).
   **                                       We don't want to have huge amounts of work per thread.
   **                                       This limits threads which use the ON_ETL_DRIVER to only
   **                                       processes this number of source rows per commit.
   **
   ** @param i_suppress_emails_bool         TRUE / FALSE - Should emails be suppressed?
   **
   ** @param i_halt_on_error_bool           If TRUE then the monitor will HALT the migration on the detection
   **                                       of an error.
   ** 
   ** @param i_master_monitors_monitor_bool If this is TRUE the master will monitor if the monitor job is 
   **                                       running.
   **
   ** @param i_external_context_controller  Sometimes you will want to control the behaviour of a migration run
   **                                       based on the setting of an external context.
   **                                       For example you may which to truncate a target before migrating to it, or
   **                                       you might want to try to keep the target data and add to it.  Rather than 
   **                                       changing the migration for each run case, use this to set a context value up.
   **                                       Example: TRUNC_TARGET=TRUE;COMPARISON=TRUE  etc... note that context setups are 
   **                                       delimited by semi-colon.  You can then check for these contexts in your steps.
   **                                       Example:-
   **
   **                                             IF pkg_pre_etl_tools.fn_get_context_value (i_attr => 'TRUNC_TARGET') = 'TRUE' THEN
   **                                                execute immediate 'truncate table target_schema.xyx';
   **                                             END IF;
   **                                       
   **
   ** @param i_job_class_name               The job class if omitted then the default of DEFAULT_JOB_CLASS
   **                                       is used.
   */
   PROCEDURE launch
   (
      i_batch                        IN NUMBER
     ,i_migration_group              IN VARCHAR2
     ,i_exception_group              IN VARCHAR2 DEFAULT NULL
     ,i_context                      IN VARCHAR2
     ,i_always_run_steps_comma_sep   IN VARCHAR2 DEFAULT NULL
     ,i_start_at_step                IN NUMBER DEFAULT 1
     ,i_start_at_thread              IN NUMBER DEFAULT NULL
     ,i_stop_at_step                 IN NUMBER DEFAULT NULL
     ,i_concurrency                  IN NUMBER DEFAULT 10
     ,i_max_rows_per_thread          IN NUMBER DEFAULT 10000
     ,i_suppress_emails_bool         IN BOOLEAN
     ,i_halt_on_error_bool           IN BOOLEAN DEFAULT FALSE
     ,i_master_monitors_monitor_bool IN BOOLEAN DEFAULT FALSE
     ,i_external_context_controller  IN VARCHAR2
     ,i_job_class_name               IN VARCHAR2 DEFAULT 'DEFAULT_JOB_CLASS'
   );

   /*------------------------------------------------------------------------------------
   ** Monitor job.  Started from the launch procedure.
   **
   ** @param i_batch                 The batch id.
   **
   ** @param i_migration_group       A migration group.
   **
   ** @param i_exception_group       Exception group.  This is a group of steps that can 
   **                                be executed if the migration encounters an exception.
   **
   ** @param i_suppress_emails_bool  BOOLEAN : If TRUE then emails are suppressed.
   **
   ** @param i_halt_on_error_bool    BOOLEAN : If TRUE then any error will cause the migration to 
   **                                halt, rather than continue.
   **
   */
   PROCEDURE pr_monitor_job
   (
      i_batch                IN NUMBER
     ,i_migration_group      IN VARCHAR2
     ,i_exception_group      IN VARCHAR2
     ,i_suppress_emails_bool IN BOOLEAN
     ,i_halt_on_error_bool   IN BOOLEAN DEFAULT FALSE
   );

   /*------------------------------------------------------------------------------------
   ** Master job.  Started from the launch procedure.
   **
   ** @param i_batch                        The batch number to run.
   **                                       This is the batch of staging rows you want to 
   **                                       import.
   **
   ** @param i_migration_group              The migration group you want to run.
   **
   ** @param i_always_run_steps_comma_sep   This is useful if the migration has specific initialisation that 
   **                                       should run EVEN IF you are starting from a later step.
   **                                       For example contexts that need to be setup.
   **                                       If this is NULL then no steps will be run before starting at 
   **                                       i_start_at_step.
   **                          
   ** @param i_start_at_step                Start at this specified step in the migration group.
   **                                       The default is 1 (i.e. the beginning).
   **
   ** @param i_start_at_thread              Under certain circumstances you might want to restart the 
   **                                       migration from a specific thread within a step.
   **
   ** @param i_stop_at_step                 Stop at this step.  NULL = run till end.
   **
   ** @param i_concurrency                  The maximum concurrency (only applies to steps that use
   **                                       the driver table ON_ETL_DRIVER) - Default is 10
   **                                       If a step doesn't use the ON_ETL_DRIVER then this has no effect.
   **
   ** @param i_max_rows_per_thread          This is a target value (sometimes a worker thread might be a little 
   **                                       above or below this value).
   **                                       We don't want to have huge amounts of work per thread.
   **                                       This limits threads which use the ON_ETL_DRIVER to only
   **                                       processes this number of source rows per commit.
   **
   ** @param i_suppress_emails_bool         TRUE / FALSE - Should emails be suppressed?
   ** 
   ** @param i_master_monitors_monitor_bool If this is TRUE the master will monitor if the monitor job is 
   **                                       running.                                   
   **
   ** @param i_job_class_name               The job class if omitted then the default of DEFAULT_JOB_CLASS
   **                                       is used.
   */
   PROCEDURE pr_master_job
   (
      i_batch                        IN NUMBER
     ,i_migration_group              IN VARCHAR2
     ,i_always_run_steps_comma_sep   IN VARCHAR2 DEFAULT NULL
     ,i_start_at_step                IN NUMBER DEFAULT 1
     ,i_start_at_thread              IN NUMBER DEFAULT NULL
     ,i_stop_at_step                 IN NUMBER DEFAULT NULL
     ,i_concurrency                  IN NUMBER DEFAULT 10
     ,i_max_rows_per_thread          IN NUMBER DEFAULT 10000
     ,i_suppress_emails_bool         IN BOOLEAN
     ,i_master_monitors_monitor_bool IN BOOLEAN DEFAULT FALSE
     ,i_job_class_name               IN VARCHAR2 DEFAULT 'DEFAULT_JOB_CLASS'
   );

   /*------------------------------------------------------------------------------------
   ** Kill the launcher and any jobs it has spawned.
   ** If you want to spawn your OWN jobs from the migration manual step then you will need
   ** to tell the migration framework that you have done this, so that the killer knows 
   ** about these manually launched jobs (and not just for the killer, but also if the migration
   ** fails unexpectedly).
   **
   ** For DBMS_PARALLEL_EXECUTE :-
   **
   **    To register    : migration_run_framework.pr_register_parallel_task(i_task_name => '<YOUR TASK>');
   **    To de-register : migration_run_framework.pr_deregister_parallel_task(i_task_name '<YOUR TASK>');
   **
   ** For normal scheduler JOBS launched from the manual steps.
   **
   **    migration_run_framework.pr_start_managed_job(i_job_name => '<MY JOB>',i_job_sql => '<YOUR SQL>' );
   **  or
   **    To register    : migration_run_framework.pr_register_managed_job(i_job_name => '<MY JOB>');
   **    To de-register : migration_run_framework.pr_deregister_managed_job(i_job_name => '<MY JOB>');
   **
   ** @param i_killer                       The name of the killer (can be anything you like).
   **
   ** @param i_skip_monitor_bool            BOOLEAN : If TRUE then don't kill the monitor.
   **
   ** Example : migration_run_framework.kill_launcher(i_killer            => 'Queen'
   **                                                 i_skip_monitor_bool => FALSE);
   */
   PROCEDURE kill_launcher
   (
      i_killer            IN VARCHAR2 DEFAULT NULL
     ,i_skip_monitor_bool BOOLEAN DEFAULT FALSE
   );
END migration_run_framework;
/
