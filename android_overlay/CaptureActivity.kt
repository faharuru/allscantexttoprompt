package com.ketik.ketik_prompt

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Toast

// Menerima teks dari menu seleksi (PROCESS_TEXT) atau Bagikan, lalu langsung
// kembali ke aplikasi asal supaya user bisa terus memilih teks lain.
class CaptureActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val t = intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
            ?: intent.getStringExtra(Intent.EXTRA_TEXT)
        if (!t.isNullOrBlank()) {
            val p = getSharedPreferences("ketik_inbox", MODE_PRIVATE)
            val old = p.getString("inbox", "") ?: ""
            p.edit().putString("inbox", if (old.isEmpty()) t else old + "\u0001" + t).apply()
            Toast.makeText(this, "Ditambahkan ke Keranjang", Toast.LENGTH_SHORT).show()
        }
        finish()
    }
}
