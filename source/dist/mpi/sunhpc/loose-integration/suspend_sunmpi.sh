#!/bin/sh
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
#  License at http://www.gridengine.sunsource.net/license.html
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
# Suspend an MPI job when its parent batch job is suspended
#
# In order to get CRE JID, adb is used to look at mprun image.
# A better way to catch an CRE job id should be provided 
# to make this suspend method work more robust.
#
#----------------
# GetCreJid 
#
GetCreJid()
{
  mprun_pid=`cat $TMPDIR/mprun_pid`
  adb=/usr/bin/adb
#  if [ "`isainfo -n`" = "sparcv9" ]; then
#  isainfo is not available on solaris 2.6
#
  if [ "`/bin/ls -l /opt/SUNWhpc/bin | grep HPC4.0`" != "" ]; then
#
#    HPC 4.0 release
#    A single mprun (32-bit binary) is provided
#
      mprun_prog_name=/opt/SUNWhpc/bin/mprun
  else
#
#    HPC 3.1 release
#    Two mprun binaries are provided
#
    if [ "`isalist | grep sparcv9`" != "" ]; then
      mprun_prog_name=/opt/SUNWhpc/bin/sparcv9/mprun
    else
      mprun_prog_name=/opt/SUNWhpc/bin/sparcv7/mprun
    fi
  fi
#
# we need to use adb and have a commands file
# we could also keep the file in same dir as this exec
# but not much of a perf loss to keep creating it in $TMPDIR
#
  adb_comms=$TMPDIR/adb-comms.$$
#
# It turns out that 32-bit and 64-bit mprun core 
# needs different adb commands to get CRE job id
#
  if [ "`/bin/ls -l /opt/SUNWhpc/bin | grep HPC4.0`" != "" ]; then
#
#    HPC 4.0 release
#    A single mprun (32-bit binary) is provided
#
       /usr/bin/echo "*task+4/D" > $adb_comms
  else
#
#    HPC 3.1 release
#    Two mprun binaries are provided
#
    if [ "`isalist | grep sparcv9`" != "" ]; then
       /usr/bin/echo "*task+8/D" > $adb_comms
    else
       /usr/bin/echo "*task+4/D" > $adb_comms
    fi
  fi
#
# get a core of the process and use adb to get job/task id
# would be nice to reference the variable directly
# through /proc interface
#
  corefile=$TMPDIR/mpcr
  ret=`/usr/bin/gcore -o $corefile $mprun_pid 2>&1`
  corefile=$corefile.$mprun_pid
  outputfile=$TMPDIR/adbres.$$
  $adb $mprun_prog_name $corefile < $adb_comms > $outputfile 2>&1

  cre_jid=`/usr/bin/grep tty_s_orig $outputfile | nawk '{print $2}'` 
  if [  "$cre_jid" -eq "" ]; then
    cre_jid=`/usr/bin/tail -2 $outputfile | nawk '{print $2}'| head -n 1`
  fi
#
# Clean up temporary files
#
  /bin/rm $adb_comms $corefile $outputfile
}

job_pid=$1

GetCreJid
#
# Save CRE Job ID for resume script
#
/usr/bin/echo $cre_jid > $TMPDIR/resume_cre_jid

/opt/SUNWhpc/bin/mpkill -STOP $cre_jid
#
# Use kill to stop the job script
#
kill -STOP -$job_pid 

# signal success to caller
exit 0

