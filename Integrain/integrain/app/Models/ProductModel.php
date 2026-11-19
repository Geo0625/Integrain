<?php

namespace App\Models;

use CodeIgniter\Model;

class ProductModel extends Model
{
    protected $table      = 'products';
    protected $primaryKey = 'product_id';
    protected $returnType = 'array';

    /** Admin list: every product with its category and raw availability flag. */
    public function adminList(): array
    {
        $rows = $this->db->query(
            "SELECT p.product_id id, p.product_code code, p.product_name name, p.category_id, c.category_name category,
                    p.description, p.image_path, p.unit, p.unit_price price, p.is_available available
               FROM products p JOIN product_categories c ON c.category_id = p.category_id
              ORDER BY c.category_name, p.product_name"
        )->getResultArray();
        foreach ($rows as &$r) {
            $r['id']          = (int) $r['id'];
            $r['category_id'] = (int) $r['category_id'];
            $r['price']       = (float) $r['price'];
            $r['available']   = (bool) (int) $r['available'];
            $r['image']       = $r['image_path'] ? base_url($r['image_path']) : null;
            unset($r['image_path']);
        }

        return $rows;
    }

    /** Next free code like RC-005. */
    public function nextCode(): string
    {
        $r = $this->db->query("SELECT IFNULL(MAX(CAST(SUBSTRING(product_code,4) AS UNSIGNED)),0)+1 n FROM products WHERE product_code REGEXP '^RC-[0-9]+$'")->getRowArray();

        return 'RC-' . str_pad((string) $r['n'], 3, '0', STR_PAD_LEFT);
    }
}
