#!/bin/sh
#
# SGE/SGEEE configuration script (Installation/Uninstallation/Upgrade/Downgrade)
# Scriptname: inst_qmaster_uninst.sh
#
#___INFO__MARK_BEGIN__
##########################################################################
#
#  The Contents of this file are made available subject to the terms of
#  the Sun Industry Standards Source License Version 1.2
#
#  Sun Microsystems Inc., March, 2001
#
#
#  Sun Industry Standards Source License Version 1.2
#  =================================================
#  The contents of this file are subject to the Sun Industry Standards
#  Source License Version 1.2 (the "License"); You may not use this file
#  except in compliance with the License. You may obtain a copy of the
#  License at http://gridengine.sunsource.net/Gridengine_SISSL_license.html
#
#  Software provided under this License is provided on an "AS IS" basis,
#  WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING,
#  WITHOUT LIMITATION, WARRANTIES THAT THE SOFTWARE IS FREE OF DEFECTS,
#  MERCHANTABLE, FIT FOR A PARTICULAR PURPOSE, OR NON-INFRINGING.
#  See the License for the specific provisions governing your rights and
#  obligations concerning the Software.
#
#  The Initial Developer of the Original Code is: Sun Microsystems, Inc.
#
#  Copyright: 2001 by Sun Microsystems, Inc.
#
#  All Rights Reserved.
#
##########################################################################
#___INFO__MARK_END__
#
# set -x

RemoveQmaster()
{
   $INFOTEXT -u "Uninstalling qmaster host"
   $INFOTEXT -n "You're going to uninstall the qmaster host now. If you are not sure,\n" \
                "what you are doing, please stop with <CTRL-C>. This procedure will, remove\n" \
                "the complete cluster configuration and all spool directories!\n" \
                "Please make a backup from your cluster configuration!\n\n"
   if [ $AUTO = "false" ]; then
      $INFOTEXT -n -ask "y" "n" -def "n" "Do you want to uninstall the master host? [n] >> "
   fi

   if [ $? = 0 ]; then
      $INFOTEXT -n "We're going to uninstall the master host now!\n"
      CheckRunningExecd

   else
      exit 0 
   fi
}

CheckRunningExecd()
{
   $INFOTEXT -n "Checking Running Execution Hosts\n"
   $INFOTEXT -log -n "Checking Running Execution Hosts\n"
   
   for h in `qconf -sel`; do

     running=`qconf -se $h | grep load_values | grep load_avg`

     if [ -z $running ]; then
        :
     else
        $INFOTEXT "Found running execution hosts, exiting uninstallation!\n"
        $INFOTEXT -log "Found running execution hosts, exiting uninstallation!\n"
        exit 0
     fi

   done
   $INFOTEXT "There are no running execution host registered!\n"
   $INFOTEXT -log "There are no running execution host registered!\n"
   ShutdownMaster
   

}

ShutdownMaster()
{
   $INFOTEXT "Shutting down scheduler and qmaster!"
   $INFOTEXT -log "Shutting down scheduler and qmaster!"
   `qconf -ks`
   `qconf -km`

   master_spool=`cat $SGE_ROOT/$SGE_CELL/common/bootstrap | grep qmaster_spool_dir | awk '{ print $2 }'`
   
   $INFOTEXT "Removing qmaster spool directory!"
   $INFOTEXT -log "Removing qmaster spool directory!"
   ExecuteAsAdmin rm -fR $master_spool

   berkeley_spool=`cat $SGE_ROOT/$SGE_CELL/common/bootstrap | grep spooling_params | awk '{ print $2 }'`

   $INFOTEXT "Removing berkeley spool directory!"
   $INFOTEXT -log "Removing berkeley spool directory!"
   ExecuteAsAdmin rm -fR $berkeley_spool

   $INFOTEXT "Removing %s directory!" $SGE_CELL
   $INFOTEXT -log "Removing %s directory!" $SGE_CELL
   ExecuteAsAdmin rm -fR $SGE_CELL
}
