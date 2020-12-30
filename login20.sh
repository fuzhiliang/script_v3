#!/usr/bin/expect

set timeout 30
spawn ssh -p [lindex $1] [lindex $2]@[lindex $3]
#spawn ssh -p [lindex $argv 0] [lindex $argv 1]@[lindex $argv 2]  #mac 版
expect {
        "(yes/no)?"
        {send "yes\n";exp_continue}
        "Password:"
        {send "[lindex $4]\n"}
}
interact
