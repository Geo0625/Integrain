<?php

namespace App\Commands;

use CodeIgniter\CLI\BaseCommand;
use CodeIgniter\CLI\CLI;
use Config\Database;

/**
 * php spark integrain:password <username> [new-password]
 * Sets (or resets) a login password. Prompts for the password when omitted.
 * (A temporary lockout after repeated failed sign-ins lifts by itself after 15 minutes; the login history is never edited.)
 */
class SetPassword extends BaseCommand
{
    protected $group       = 'Integrain';
    protected $name        = 'integrain:password';
    protected $description = 'Set or reset the password of a user account.';
    protected $usage       = 'integrain:password <username> [new-password]';
    protected $arguments   = ['username' => 'The login username', 'new-password' => 'Optional; you will be asked if omitted'];

    public function run(array $params)
    {
        $username = $params[0] ?? CLI::prompt('Username');
        $password = $params[1] ?? CLI::prompt('New password (min. 8 characters)');
        if (strlen($password) < 8) {
            CLI::error('The password must be at least 8 characters.');

            return EXIT_ERROR;
        }
        $db   = Database::connect();
        $user = $db->table('users')->where('username', $username)->get()->getRowArray();
        if (! $user) {
            CLI::error("No account with the username \"{$username}\".");

            return EXIT_ERROR;
        }
        $db->table('users')->where('user_id', $user['user_id'])->update(['password_hash' => password_hash($password, PASSWORD_DEFAULT)]);
        CLI::write("Password updated for \"{$username}\".", 'green');

        return EXIT_SUCCESS;
    }
}
