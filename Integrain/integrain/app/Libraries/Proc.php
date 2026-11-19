<?php

namespace App\Libraries;

use Config\Database;

/**
 * Thin wrapper for calling the MariaDB stored procedures defined in integrain_db.
 *
 * - Builds the CALL with CodeIgniter's own escaping.
 * - Reads EVERY result set (some procedures return 2-3) and always drains the
 *   connection so later queries never fail with "Commands out of sync".
 * - Casts INT / DECIMAL columns to real numbers using result metadata.
 */
class Proc
{
    private const INT_TYPES   = [MYSQLI_TYPE_TINY, MYSQLI_TYPE_SHORT, MYSQLI_TYPE_INT24, MYSQLI_TYPE_LONG, MYSQLI_TYPE_LONGLONG, MYSQLI_TYPE_YEAR];
    private const FLOAT_TYPES = [MYSQLI_TYPE_DECIMAL, MYSQLI_TYPE_NEWDECIMAL, MYSQLI_TYPE_FLOAT, MYSQLI_TYPE_DOUBLE];

    private static bool $zoneSet = false;

    /** Connects and keeps CURDATE()/NOW() (and timestamp columns) on Philippine time regardless of server settings. */
    public function init(): \mysqli
    {
        $db = Database::connect();
        $db->initialize();
        /** @var \mysqli $my */
        $my = $db->connID;
        if (! self::$zoneSet) {
            $my->query("SET time_zone = '+08:00'");
            self::$zoneSet = true;
        }

        return $my;
    }

    /** @return list<list<array<string,mixed>>> every result set */
    public function sets(string $name, array $args = []): array
    {
        if (! preg_match('/^(sp|fn)_[a-z0-9_]+$/', $name)) {
            throw new \InvalidArgumentException('Invalid procedure name.');
        }
        $db = Database::connect();
        $my = $this->init();

        $sql = 'CALL ' . $name . '(' . implode(',', array_map(static fn ($v) => $db->escape($v), $args)) . ')';
        if (! $my->real_query($sql)) {
            throw new \mysqli_sql_exception($my->error, $my->errno);
        }

        $sets = [];
        do {
            $res = $my->store_result();
            if ($res instanceof \mysqli_result) {
                $sets[] = $this->cast($res);
                $res->free();
            }
        } while ($my->more_results() && $my->next_result());

        return $sets;
    }

    /** Rows of the first result set. */
    public function rows(string $name, array $args = []): array
    {
        return $this->sets($name, $args)[0] ?? [];
    }

    /** First row of the first result set, or null. */
    public function one(string $name, array $args = []): ?array
    {
        return $this->rows($name, $args)[0] ?? null;
    }

    private function cast(\mysqli_result $res): array
    {
        $map = [];
        foreach ($res->fetch_fields() as $f) {
            if (in_array($f->type, self::INT_TYPES, true)) {
                $map[$f->name] = 'int';
            } elseif (in_array($f->type, self::FLOAT_TYPES, true)) {
                $map[$f->name] = 'float';
            }
        }
        $rows = [];
        while ($row = $res->fetch_assoc()) {
            foreach ($map as $col => $t) {
                if ($row[$col] !== null) {
                    $row[$col] = $t === 'int' ? (int) $row[$col] : (float) $row[$col];
                }
            }
            $rows[] = $row;
        }

        return $rows;
    }
}
