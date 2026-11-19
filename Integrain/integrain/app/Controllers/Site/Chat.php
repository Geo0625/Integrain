<?php

namespace App\Controllers\Site;

use App\Controllers\ApiController;
use App\Libraries\Chatbot;

/**
 * Website chat. A visitor is identified only by a random token kept in the browser;
 * the database stores the SHA-256 hash of it (chat_visitors.token_hash).
 * The conversation is always derived from the token - the client never sends an id.
 */
class Chat extends ApiController
{
    public function history()
    {
        return $this->guard(function () {
            $conv = $this->open();
            if (! is_array($conv)) {
                return $conv;
            }

            return ['messages' => $this->proc->rows('sp_chat_get_history', [$conv['conversation_id'], 50])];
        });
    }

    public function send()
    {
        $in   = $this->input();
        $text = trim((string) ($in['text'] ?? ''));
        if ($text === '' || mb_strlen($text) > 500) {
            return $this->bad('Please type a message (up to 500 characters).', 422);
        }

        return $this->guard(function () use ($text) {
            $conv = $this->open();
            if (! is_array($conv)) {
                return $conv;
            }
            $id = $conv['conversation_id'];
            $this->proc->sets('sp_chat_add_message', [$id, 'Visitor', $text, null]);
            [$reply, $productId] = (new Chatbot())->reply($text, $this->proc);
            $this->proc->sets('sp_chat_add_message', [$id, 'Chatbot', $reply, $productId]);

            return ['reply' => $reply];
        });
    }

    /** @return array|\CodeIgniter\HTTP\ResponseInterface */
    private function open()
    {
        $token = (string) ($this->input()['token'] ?? '');
        if (! preg_match('/^[A-Za-z0-9_-]{32,128}$/', $token)) {
            return $this->bad('Invalid chat session.', 422);
        }

        return $this->proc->one('sp_chat_open_session', [hash('sha256', $token)]);
    }
}
