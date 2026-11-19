<?php

namespace App\Controllers;

use App\Libraries\Proc;
use CodeIgniter\API\ResponseTrait;
use CodeIgniter\HTTP\ResponseInterface;

/** Base class for every JSON endpoint. */
abstract class ApiController extends BaseController
{
    use ResponseTrait;

    protected Proc $proc;

    public function __construct()
    {
        $this->proc = new Proc();
        $this->proc->init();
    }

    /** JSON body (or form post) merged with query string. */
    protected function input(): array
    {
        $body = [];
        $ct   = $this->request->getHeaderLine('Content-Type');
        if (stripos($ct, 'application/json') !== false) {
            $decoded = json_decode((string) $this->request->getBody(), true);
            $body    = is_array($decoded) ? $decoded : [];
        } else {
            $body = $this->request->getPost() ?? [];
        }

        return $body + ($this->request->getGet() ?? []);
    }

    protected function user(): array
    {
        return session('user') ?? [];
    }

    protected function ok($data = [], int $status = 200): ResponseInterface
    {
        return $this->response->setStatusCode($status)
            ->setHeader('Cache-Control', 'no-store')
            ->setJSON($data);
    }

    protected function bad(string $message, int $status = 422, array $errors = []): ResponseInterface
    {
        $out = ['message' => $message];
        if ($errors) {
            $out['errors'] = $errors;
        }

        return $this->response->setStatusCode($status)->setHeader('Cache-Control', 'no-store')->setJSON($out);
    }

    /**
     * Run a callback and translate database exceptions into clean API errors.
     * Business-rule errors raised by the stored procedures (SIGNAL 45000 / errno 1644)
     * are shown to the user as-is because they are written for people to read.
     */
    protected function guard(callable $fn): ResponseInterface
    {
        try {
            $res = $fn();

            return $res instanceof ResponseInterface ? $res : $this->ok($res);
        } catch (\mysqli_sql_exception $e) {
            return $this->dbError($e);
        } catch (\CodeIgniter\Database\Exceptions\DatabaseException $e) {
            return $this->dbError($e);
        }
    }

    protected function dbError(\Throwable $e): ResponseInterface
    {
        $code = (int) $e->getCode();
        $msg  = $e->getMessage();
        if ($code === 1644) {
            return $this->bad($msg, 422);
        }
        if ($code === 1062) {
            $what = 'That value';
            foreach (['employee_code' => 'That employee code', 'username' => 'That username', 'product_code' => 'That product code', 'category_name' => 'That category name', 'employee_id' => 'That employee already has a login account'] as $k => $label) {
                if (str_contains($msg, $k)) {
                    $what = $label;
                    break;
                }
            }

            return $this->bad($what . ' is already in use.', 409);
        }
        if (in_array($code, [1451, 1452], true)) {
            return $this->bad('This record is linked to other data and cannot be changed that way.', 409);
        }
        if (in_array($code, [1048, 1264, 1265, 1292, 1366, 1406, 1411, 3819, 4025], true)) {
            return $this->bad('One of the values is missing or not valid.', 422);
        }
        log_message('error', 'DB error {code}: {msg}', ['code' => $code, 'msg' => $msg]);

        return $this->bad('Something went wrong on the server. Please try again.', 500);
    }

    /** Validate $data against CI4 rules; returns an error response or null. */
    protected function invalid(array $data, array $rules): ?ResponseInterface
    {
        $v = service('validation');
        $v->reset();
        if (! $v->setRules($rules)->run($data)) {
            $errors = $v->getErrors();

            return $this->bad((string) reset($errors), 422, $errors);
        }

        return null;
    }

    /** Validate against a named rule group in Config\Validation (like a Laravel Form Request). */
    protected function validated(array $data, string $group): ?ResponseInterface
    {
        $v = service('validation');
        $v->reset();
        if (! $v->run($data, $group)) {
            $errors = $v->getErrors();

            return $this->bad((string) reset($errors), 422, $errors);
        }

        return null;
    }

    /** Normalise optional text: trim, '' -> null. */
    protected function text($v, int $max = 255): ?string
    {
        if ($v === null) {
            return null;
        }
        $v = trim((string) $v);

        return $v === '' ? null : mb_substr($v, 0, $max);
    }
}
