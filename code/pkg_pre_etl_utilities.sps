CREATE OR REPLACE PACKAGE pkg_pre_etl_utilities AUTHID CURRENT_USER IS

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
   ** Function to get parameter.  This is result cached.
   ** DO NOT USE IN FORMS (it causes forms NOT TO COMPILE).
   **
   ** @param i_param_name               The parameter name.
   **
   */
   FUNCTION fn_get_param(i_param_name IN VARCHAR2) RETURN VARCHAR2 result_cache;

   /*------------------------------------------------------------------------------------
   ** Start Monitoring Something.
   **
   ** @param i_introspect_step          The step being introspected.
   **
   ** @param i_introspect_context       This is a way of allowing users to specify the context of what they
   **                                   are monitoring...
   **                                   In the case of PRE_ETL this will be the name of the document
   **                                   being constructed.
   **
   ** @param i_aspect_being_monitored   What are we monitoring?  Defined by the user.
   **                                   The user of this routine will wrap whatever it is they want
   **                                   to monitor between a start and end call.
   **
   ** @param i_mode                     START or END only.
   */
   PROCEDURE pr_introspect_monitoring
   (
      i_introspect_step        IN VARCHAR2
     ,i_introspect_context     IN VARCHAR2
     ,i_aspect_being_monitored IN VARCHAR2
     ,i_mode                   IN VARCHAR2
   );
   /*------------------------------------------------------------------------------------
   ** Create the introspection table.
   **
   */
   PROCEDURE pr_create_intro_table;

   /*------------------------------------------------------------------------------------
   ** Dump the stats out to the context.
   **
   */
   PROCEDURE pr_dump_introspection_stats;

   /*------------------------------------------------------------------------------------
   ** Converts a BLOB to a CLOB
   **
   ** @param pbli_blob                 The blob to convert to clob.
   **
   ** @param pvi_tf_raise_ex_on_fail   Raise an exception on failure to convert? (T/F).
   **
   ** @return                          A clob.
   */
   FUNCTION fn_convert_blob_to_clob
   (
      i_blob                IN BLOB
     ,i_tf_raise_ex_on_fail IN VARCHAR2
   ) RETURN CLOB
      PARALLEL_ENABLE;

   /*------------------------------------------------------------------------------------
   ** Converts a CLOB to a BLOB
   **
   ** @param pci_clob               The clob to convert to blob
   **
   ** @return                       A blob.
   */
   FUNCTION fn_convert_clob_to_blob(i_clob IN CLOB) RETURN BLOB
      PARALLEL_ENABLE;

   /*------------------------------------------------------------------------------------
   ** Takes a CLOB and compresses it (lz compression) into a BLOB
   **
   ** @param pci_clob               The clob to compress.
   **
   ** @return                       A blob containing the compressed clob.
   */
   FUNCTION fn_clob_to_compressed_blob(i_clob IN CLOB) RETURN BLOB
      PARALLEL_ENABLE;

   /*------------------------------------------------------------------------------------
   ** Takes a BLOB and compresses it (lz compression).
   **
   ** @param pbli_blob              The blob to compress.
   **
   ** @return                       A blob containing compressed data.
   */
   FUNCTION fn_compress_blob(i_blob IN BLOB) RETURN BLOB
      PARALLEL_ENABLE;

   /*------------------------------------------------------------------------------------
   ** Takes a compressed BLOB and uncompresses it (lz uncompression).
   **
   ** @param pbli_compressed_blob   The blob to uncompress.
   **
   ** @return                       An uncompressed blob.
   */
   FUNCTION fn_uncompress_blob(i_compressed_blob IN BLOB) RETURN BLOB
      PARALLEL_ENABLE;

   /*------------------------------------------------------------------------------------
   ** Takes a compressed BLOB and uncompresses it (lz uncompression) and
   ** converts it into a CLOB.
   **
   ** @param pbi_compressed_blob    The blob to uncompress.
   **
   ** @return                       A clob containing the uncompressed blob.
   */
   FUNCTION fn_uncompress_blob_to_clob(i_compressed_blob IN BLOB)
      RETURN CLOB
      PARALLEL_ENABLE;

   /*------------------------------------------------------------------------------------
   ** Takes a clob and returns a hash in a RAW (16)
   **
   ** @param i_clob                    The clob to get a hash for.
   **
   ** @return                          A hash as a RAW.
   */
   FUNCTION fn_get_hash_for_clob(i_clob IN CLOB) RETURN RAW
      PARALLEL_ENABLE;

   /*------------------------------------------------------------------------------------
   ** Gets the last time the pre_etl data was changed.
   ** Useful if you want to know if its worth taking a backup
   **
   ** @return                          A timestamp of the last time the meta data was changed.
   */
   FUNCTION fn_get_last_metadata_chgd_time RETURN TIMESTAMP;
END pkg_pre_etl_utilities;
/
