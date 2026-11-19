<?php

namespace App\Libraries;

use App\Models\StoreModel;

/**
 * Small rule-based store assistant. Answers come from the database
 * (store_settings, products, job_openings) so they never go out of date.
 * Returns [reply text, product_id or null].
 */
class Chatbot
{
    public function reply(string $text, Proc $proc): array
    {
        $q  = mb_strtolower($text);
        $store = model(StoreModel::class);
        $s     = $store->publicSettings();
        $has = static fn (array $words) => (bool) array_filter($words, static fn ($w) => str_contains($q, $w));
        $name = $s['store_name'] ?? "Jun & Bebot's Bigasan";

        if ($has(['hour', 'open', 'close', 'schedule', 'oras', 'bukas'])) {
            return ['We are open ' . ($s['store_hours'] ?? 'daily') . '. Hope to see you!', null];
        }
        if ($has(['where', 'location', 'address', 'saan', 'directions', 'map', 'find you'])) {
            return ['You can find ' . $name . ' at ' . ($s['address'] ?? 'our store') . '. The map is on the home page, near the bottom.', null];
        }
        if ($has(['contact', 'phone', 'call', 'number', 'text you'])) {
            return [isset($s['contact_no']) ? 'You can reach us at ' . $s['contact_no'] . '.' : 'Please visit or message us here in the chat and our team will get back to you.', null];
        }
        if ($has(['apply', 'job', 'hiring', 'hire', 'trabaho', 'work for'])) {
            $jobs = $store->openJobs();
            $list = $jobs ? implode(', ', array_map(static fn ($j) => $j['description'], $jobs)) : 'no open positions right now';

            return ['Current openings: ' . $list . '. Tap "Apply for a job" to start your application.', null];
        }

        $products = $proc->rows('sp_get_product_list', [null]);
        $hits = [];
        foreach ($products as $p) {
            $tokens = array_filter(preg_split('/[^a-z0-9]+/i', mb_strtolower($p['product_name'])), static fn ($t) => mb_strlen($t) >= 4 && ! in_array($t, ['rice', 'milled'], true));
            foreach ($tokens as $t) {
                if (str_contains($q, $t)) {
                    $hits[] = $p;
                    break;
                }
            }
        }
        if ($hits) {
            $lines = array_map(static fn ($p) => $p['product_name'] . ': ₱' . number_format($p['unit_price'], 2) . ' per ' . $p['unit'] . ($p['availability'] === 'Available' ? '' : ' (currently unavailable)'), array_slice($hits, 0, 4));

            return [implode("\n", $lines), count($hits) === 1 ? $hits[0]['product_id'] : null];
        }
        if ($has(['price', 'how much', 'magkano', 'cost', 'presyo', 'rice', 'cook', 'product', 'bigas', 'sell'])) {
            $avail = array_values(array_filter($products, static fn ($p) => $p['availability'] === 'Available'));
            if (! $avail) {
                return ['Our product list is being updated. Please check back soon.', null];
            }
            $lines = array_map(static fn ($p) => $p['product_name'] . ' (' . $p['category'] . '): ₱' . number_format($p['unit_price'], 2) . ' per ' . $p['unit'], array_slice($avail, 0, 6));

            return ["Here is what we have in stock:\n" . implode("\n", $lines) . "\nAsk about a specific rice and I will tell you more.", null];
        }
        if ($has(['hello', 'hi ', 'hey', 'kumusta', 'good morning', 'good afternoon']) || preg_match('/^hi\b/', $q)) {
            return ['Hello! Welcome to ' . $name . '. Ask me about our rice, prices, store hours, or applying to join our team.', null];
        }

        return ['Thanks for your message! I can help with our rice and prices, store hours, location, or job openings. To apply for a job, tap "Apply for a job".', null];
    }
}
