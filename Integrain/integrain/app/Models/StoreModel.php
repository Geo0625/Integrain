<?php

namespace App\Models;

use CodeIgniter\Model;

/** Public store data: settings, product categories and open job positions. */
class StoreModel extends Model
{
    protected $table      = 'store_settings';
    protected $primaryKey = 'setting_key';
    protected $returnType = 'array';

    /** key => value, leaving out values the owner has not filled in yet ("Update this: …"). */
    public function publicSettings(): array
    {
        $map = [];
        foreach ($this->db->table('v_store_info')->get()->getResultArray() as $row) {
            if (! str_starts_with($row['setting_value'], 'Update this')) {
                $map[$row['setting_key']] = $row['setting_value'];
            }
        }

        return $map;
    }

    public function categories(): array
    {
        return $this->db->table('product_categories')->orderBy('category_id')->get()->getResultArray();
    }

    public function openJobs(): array
    {
        return $this->db->table('v_open_jobs')->orderBy('opening_id')->get()->getResultArray();
    }
}
