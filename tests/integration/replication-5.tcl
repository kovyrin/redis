start_server {tags {"repl"}} {
    start_server {} {
        r -1 config set slave-allow-key-expires yes

        test {First server should have role slave after SLAVEOF} {
            r -1 slaveof [srv 0 host] [srv 0 port]
            after 1000
            s -1 role
        } {slave}

        if {$::accurate} {set numops 50000} else {set numops 5000}

        test {MASTER and SLAVE consistency with expire + allowed slave expires} {
            createComplexDataset r $numops useexpire
            after 4000 ;# Make sure everything expired before taking the digest
            r keys *   ;# Force DEL syntesizing to slave
            after 1000 ;# Wait another second. Now everything should be fine.
            if {[r debug digest] ne [r -1 debug digest]} {
                set csv1 [csvdump r]
                set csv2 [csvdump {r -1}]
                set fd [open /tmp/repldump1.txt w]
                puts -nonewline $fd $csv1
                close $fd
                set fd [open /tmp/repldump2.txt w]
                puts -nonewline $fd $csv2
                close $fd
                puts "Master - Slave inconsistency"
                puts "Run diff -u against /tmp/repldump*.txt for more info"
            }
            assert_equal [r debug digest] [r -1 debug digest]
        }

        test {Keys should expire on the slave with slave-allow-key-expires=yes} {
            r -1 set x bar
            r -1 expire x 1
            after 1500
            list [r -1 get x] [r -1 exists x]
        } {{} 0}

        r -1 config set slave-allow-key-expires no

        test {Keys should not expire on the slave with slave-allow-key-expires=yes} {
            r -1 set x bar
            r -1 expire x 1
            after 1500
            list [r -1 get x] [r -1 exists x]
        } {bar 1}
    }
}
