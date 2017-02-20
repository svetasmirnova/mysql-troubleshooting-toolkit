/*
 * Parses binary log and creates separate file for each thread in it
 */

<?php

$handles = array();

$binlog = fopen($argv[1], 'r');

if (!$binlog)
        exit("Unable to open log: " . $argv[1]);

$current = fopen('header.sql', 'w');
while (($buffer = fgets($binlog)) !== false)
{
        //$matches;
        if (preg_match('/Query\s+(thread_id=\d+)/', $buffer, $matches))
        {
                if (!array_key_exists($matches[1], $handles)) {
                        $handles[$matches[1]] = fopen($matches[1], 'w');
                }
                $current = $handles[$matches[1]];
        }
        fwrite($current, $buffer);
}

fclose($current);
fclose($binlog);

foreach ($handles as $handle)
        fclose($handle);

?>

