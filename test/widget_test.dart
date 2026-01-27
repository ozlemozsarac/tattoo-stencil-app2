import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Placeholder test', () {
    expect(1 + 1, 2);
  });
}
```

4. **Commit:** `Add placeholder test`

---

## ADIM 4: GitHub Actions'ı Aktifleştirme ve İlk Build

### 4.1 Actions Sekmesine Git
```
https://github.com/kullaniciadin/tattoo-stencil-app
→ Üstte "Actions" sekmesine tıkla
```

**Göreceklerin:**
```
┌────────────────────────────────────────────┐
│ Actions                                    │
├────────────────────────────────────────────┤
│ Get started with GitHub Actions            │
│                                            │
│ [I understand, enable Actions]             │
└────────────────────────────────────────────┘
```

**"I understand my workflows..." butonuna tıkla**

---

### 4.2 Manuel Workflow Başlatma

**İlk build'i tetiklemek için:**

1. **Actions sekmesinde sol tarafta:**
```
   Workflows
   └─ Build Android APK  ← Buna tıkla
```

2. **Sağ tarafta:**
```
   [Run workflow ▼] butonu görünür
```

3. **"Run workflow" → "Run workflow" (yeşil buton)**

**Build başladı! 🎉**

---

### 4.3 Build Sürecini İzleme

**Ekranda göreceksin:**
```
┌────────────────────────────────────────────────────┐
│ Build Android APK                                  │
├────────────────────────────────────────────────────┤
│ ● workflow_run_123                                 │
│   ⏱️ Running... (5 minutes)                        │
│                                                    │
│   Jobs:                                            │
│   ✓ Checkout code         (10s)                    │
│   ✓ Setup Java            (15s)                    │
│   ✓ Setup Flutter         (45s)                    │
│   ⏳ Get dependencies      (running...)            │
│   ⏸️ Run tests             (pending)                │
│   ⏸️ Build APK             (pending)                │
│   ⏸️ Upload APK            (pending)                │
└────────────────────────────────────────────────────┘
```

**Bekleme süresi:** ~5-8 dakika (Flutter setup + build)

---

### 4.4 Build Tamamlandığında

**Tüm adımlar yeşil ✓ olacak:**
```
┌────────────────────────────────────────────────────┐
│ ✅ Build Android APK                               │
│    workflow_run_123 - Completed in 6m 32s          │
│                                                    │
│ Jobs:                                              │
│ ✓ Checkout code                                    │
│ ✓ Setup Java                                       │
│ ✓ Setup Flutter                                    │
│ ✓ Get dependencies                                 │
│ ✓ Run tests                                        │
│ ✓ Build APK                                        │
│ ✓ Upload APK                                       │
│                                                    │
│ Artifacts (1)                                      │
│ 📦 app-release-apk (23.4 MB)      [Download]       │
└────────────────────────────────────────────────────┘
```

---

## ADIM 5: APK'yı İndirme

### Yöntem 1: Artifacts'tan İndirme (Her Build İçin)

1. **Actions sekmesinde tamamlanmış build'e tıkla**
2. **En altta "Artifacts" bölümünü bul**
3. **"app-release-apk"** yanındaki **Download** butonuna tıkla
4. **ZIP dosyası inecek** → Aç → İçinde `app-release.apk` var

**APK konumu:**
```
Downloads/
└─ app-release-apk.zip
   └─ app-release.apk  ← Bu dosya
```

---

### Yöntem 2: Release Oluşturma (Versiyonlu APK)

**Daha profesyonel, müşterilere dağıtım için:**

#### 5.1 Release Oluştur

1. **GitHub ana sayfada sağ tarafta:**
```
   Releases
   └─ [Create a new release] ← Tıkla
```

2. **"Choose a tag" dropdown:**
```
   Type: v0.1.0
   [Create new tag: v0.1.0 on publish]
```

3. **"Release title":**
```
   v0.1.0 - Initial Release
