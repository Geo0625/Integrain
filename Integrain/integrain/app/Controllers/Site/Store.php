<?php

namespace App\Controllers\Site;

use App\Controllers\ApiController;
use App\Models\StoreModel;

/** Public read-only data for the website: store info, products, categories, open jobs. */
class Store extends ApiController
{
    public function info()
    {
        return $this->guard(fn () => model(StoreModel::class)->publicSettings());
    }

    public function products()
    {
        return $this->guard(function () {
            $q = $this->text($this->request->getGet('q'), 100);

            return array_map([self::class, 'shapeProduct'], $this->proc->rows('sp_get_product_list', [$q]));
        });
    }

    public function categories()
    {
        return $this->guard(fn () => model(StoreModel::class)->categories());
    }

    public function jobs()
    {
        return $this->guard(fn () => model(StoreModel::class)->openJobs());
    }

    /** Public product shape used by the website. */
    public static function shapeProduct(array $p): array
    {
        return [
            'id'          => $p['product_id'],
            'code'        => $p['product_code'],
            'name'        => $p['product_name'],
            'category'    => $p['category'],
            'description' => $p['description'],
            'image'       => $p['image_path'] ? base_url($p['image_path']) : null,
            'unit'        => $p['unit'],
            'price'       => $p['unit_price'],
            'available'   => $p['availability'] === 'Available',
        ];
    }
}
