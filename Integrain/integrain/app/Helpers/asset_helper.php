<?php

/**
 * asset('css/theme.css')  ->  http://localhost:8080/assets/css/theme.css?v=1731400000
 * The version changes whenever the file changes, so browsers never keep an old copy.
 */
if (! function_exists('asset')) {
    function asset(string $path): string
    {
        $file    = FCPATH . 'assets/' . ltrim($path, '/');
        $version = is_file($file) ? filemtime($file) : 0;

        return base_url('assets/' . ltrim($path, '/')) . '?v=' . $version;
    }
}
