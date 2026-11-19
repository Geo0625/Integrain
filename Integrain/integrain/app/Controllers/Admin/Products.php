<?php

namespace App\Controllers\Admin;

use App\Controllers\ApiController;
use App\Models\ProductModel;

class Products extends ApiController
{
    private const MIMES = ['image/jpeg' => 'jpg', 'image/png' => 'png', 'image/webp' => 'webp', 'image/gif' => 'gif'];
    private const DIR   = 'uploads/products/';

    public function index()
    {
        return $this->guard(fn () => model(ProductModel::class)->adminList());
    }

    /** POST api/admin/products (create) | POST api/admin/products/{id} (update). multipart/form-data */
    public function save($id = null)
    {
        $in = $this->input();
        if ($r = $this->validated($in, 'productSave')) {
            return $r;
        }

        return $this->guard(function () use ($in, $id) {
            $id  = $id === null ? null : (int) $id;
            $old = $id ? model(ProductModel::class)->find($id) : null;
            if ($id && ! $old) {
                return $this->bad('Product not found.', 404);
            }

            $path = $old['image_path'] ?? null;
            $file = $this->request->getFile('image');
            if ($file && $file->getError() !== UPLOAD_ERR_NO_FILE) {
                if (! $file->isValid() || $file->getSize() > 5 * 1024 * 1024 || ! isset(self::MIMES[$file->getMimeType()])) {
                    return $this->bad('Choose a JPG, PNG, WebP or GIF image no larger than 5 MB.', 422);
                }
                $name = bin2hex(random_bytes(12)) . '.' . self::MIMES[$file->getMimeType()];
                $file->move(FCPATH . self::DIR, $name);
                $this->removeFile($path);
                $path = self::DIR . $name;
            }

            $row = $this->proc->one('sp_save_product', [
                $id, $this->text($in['code'] ?? null, 20) ?? ($old['product_code'] ?? model(ProductModel::class)->nextCode()),
                $this->text($in['name'], 100), (int) $in['category_id'], $this->text($in['description'] ?? null),
                $path, $in['unit'], (float) $in['price'],
                isset($in['available']) ? ((int) filter_var($in['available'], FILTER_VALIDATE_BOOLEAN)) : null,
                $this->user()['id'],
            ]);

            return $this->ok(['product_id' => $row['product_id']], $id ? 200 : 201);
        });
    }

    /** POST api/admin/products/{id}/availability {available: true|false} */
    public function availability(int $id)
    {
        $in = $this->input();

        return $this->guard(fn () => $this->proc->one('sp_set_product_availability', [$id, filter_var($in['available'] ?? false, FILTER_VALIDATE_BOOLEAN) ? 1 : 0, $this->user()['id']]));
    }

    /** POST api/admin/categories {id?, name} */
    public function saveCategory()
    {
        $in = $this->input();
        if ($r = $this->validated($in, 'categorySave')) {
            return $r;
        }

        return $this->guard(fn () => $this->ok($this->proc->one('sp_save_category', [isset($in['id']) && $in['id'] !== '' ? (int) $in['id'] : null, trim($in['name'])]), 201));
    }

    private function removeFile(?string $path): void
    {
        if ($path && str_starts_with($path, self::DIR) && ! str_contains($path, '..')) {
            @unlink(FCPATH . $path);
        }
    }
}
