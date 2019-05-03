BEGIN
   pkg_pre_etl_tools.pr_set_context(i_attr  => migration_run_framework.fn_ctx_run_context
                                   ,i_value => '?');

   pkg_pre_etl_tools.pr_reset_seq(i_sequence_name   => 'agl_seq_no_seq'
                                 ,i_sequence_owner  => 'pre_etl_owner'
                                 ,i_based_on_table  => 'aud_generator_log'
                                 ,i_based_on_schema => 'pre_etl_owner'
                                 ,i_based_on_column => 'seq_no');
   --
   pkg_pre_etl_tools.pr_reset_seq(i_sequence_name   => 'on_etl_seq_oel'
                                 ,i_sequence_owner  => 'pre_etl_owner'
                                 ,i_based_on_table  => 'on_etl_log'
                                 ,i_based_on_schema => 'pre_etl_owner'
                                 ,i_based_on_column => 'log_id');
   --
   pkg_pre_etl_tools.pr_reset_seq(i_sequence_name   => 'pre_etl_seq_pejl'
                                 ,i_sequence_owner  => 'pre_etl_owner'
                                 ,i_based_on_table  => 'pre_etl_json_lines'
                                 ,i_based_on_schema => 'pre_etl_owner'
                                 ,i_based_on_column => 'id');
   --
   pkg_pre_etl_tools.pr_reset_seq(i_sequence_name   => 'pre_etl_seq_perjl'
                                 ,i_sequence_owner  => 'pre_etl_owner'
                                 ,i_based_on_table  => 'pre_etl_related_json_lines'
                                 ,i_based_on_schema => 'pre_etl_owner'
                                 ,i_based_on_column => 'id');
   --
   pkg_pre_etl_tools.pr_reset_seq(i_sequence_name   => 'pre_etl_seq_rg'
                                 ,i_sequence_owner  => 'pre_etl_owner'
                                 ,i_based_on_table  => 'pre_etl_related_json_lines'
                                 ,i_based_on_schema => 'pre_etl_owner'
                                 ,i_based_on_column => 'relationship_group_id');
   pkg_pre_etl_tools.pr_destroy_context_attr(i_attr => migration_run_framework.fn_ctx_run_context);

END;
/

EXIT;
