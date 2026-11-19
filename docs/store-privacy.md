# Blue Serial mağaza gizlilik beyanları

Bu belge geliştirici içindir. Kullanıcıya sunulacak Türkçe ve İngilizce metin [Gizlilik Politikası](../PRIVACY_POLICY.md) dosyasındadır. Aşağıdaki beyanlar mevcut kaynak kodun incelenmesine dayanır; mağazaya gönderilecek son sürüm ve bağımlılıkları aynı davranışı korumalıdır.

## Politikanın yayımlanması

Politikayı, depo herkese açıldıktan sonra herkesin oturum açmadan okuyabildiği kalıcı bir adreste yayımlayın. GitHub Pages veya kendi alan adınız kullanılabilir. Google Play; etkin, herkese açık, coğrafi kısıtlaması olmayan, ziyaretçilerin değiştiremediği ve PDF olmayan bir politika adresi ister. Politikanın uygulama içinde bağlantı veya metin olarak da bulunması gerekir. [Google Play Kullanıcı Verileri politikası](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en).

Yayımlanan adresi Play Console'daki gizlilik politikası alanına ve App Store Connect'teki **Privacy Policy URL** alanına girin. **Ayarlar → Hakkında → Gizlilik Politikası** gibi kolay bulunur bir uygulama içi giriş ekleyin. Apple da hem mağaza kaydında hem uygulama içinde erişilebilir bir politika bağlantısı ister. Bu belge değişikliği uygulamaya henüz böyle bir giriş eklemez. [Apple App Review Guidelines 5.1.1](https://developer.apple.com/app-store/review/guidelines/#privacy).

Politikadaki geliştirici adı şu an depodaki lisans ve Hakkında ekranına göre **ysfgr (GitHub: ysfgrl)** olarak yazılmıştır. Mağazadaki yayıncı bilgisiyle kontrol edin. Mevcut iletişim mekanizması GitHub Issues'dır; özel başvurular için bir e-posta adresi kullanacaksanız yayımdan önce her iki dilde de güncelleyin.

## Google Play Data safety

Mevcut kodda hesap, geliştirici sunucusuna veri aktarımı, reklam, analiz veya otomatik hata raporlama entegrasyonu bulunmuyor. Kayıtlı komutlar ve dil seçimi yerel tutuluyor. Seri içerik kullanıcının seçtiği cihaza iletiliyor; günlük dosyası dışa aktarma ve panoya kopyalama kullanıcı işlemiyle yapılıyor.

Bu davranışı koruyan sürüm için **veri toplanmıyor ve paylaşılmıyor** beyanı değerlendirilebilir. Yerel işleme toplama kapsamı dışındadır; kullanıcının başlattığı ve paylaşımı beklediği aktarımlar için ayrıca paylaşım istisnası vardır. Bağlı cihazın hedefi ve dağıtılacak sürümün tüm aktarım yolları bu koşullarla karşılaştırılmalıdır. [Google Play Data safety açıklamaları](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en).

Hesap oluşturma yoktur; hesap silme akışı mevcut değildir. Yerel kayıt silme ve dışa aktarılan dosyaların ayrıca kaldırılması politikada açıklanmıştır. Seri bağlantıya uygulama düzeyinde şifreleme eklenmediğinden, şifreli aktarım hakkında doğrulanmamış bir beyan vermeyin.

## App Store App Privacy

Mevcut iOS uygulaması ve aynı veri davranışını koruyan bağımlılıklar için **Data Not Collected** seçeneği değerlendirilebilir. Apple'ın toplama tanımı, geliştiricinin veya üçüncü taraf ortaklarının gerçek zamanlı isteği karşılamak için gerekli süreden daha uzun erişebildiği cihaz dışı aktarıma dayanır. Kaynak kodda bu tür bir toplama entegrasyonu yoktur. [Apple App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/).

Takip entegrasyonu bulunmuyor. Gizlilik politikası, App Privacy beyanı ve `PrivacyInfo.xcprivacy` ayrı öğelerdir; politika dosyası, gerekli SDK gizlilik bildirimlerinin ve required reason API beyanlarının yerini tutmaz. Son iOS arşivindeki uygulama ve SDK bildirimlerini ayrıca kontrol edin. [Apple üçüncü taraf SDK gereklilikleri](https://developer.apple.com/support/third-party-SDK-requirements/).

## Mevcut iOS işlev kapsamı

Depodaki iOS seri port eklentisi şu an boş port listesi döndürüyor ve bağlantı/yazma işlemlerini desteklemiyor. Mağaza açıklaması çalışmayan seri haberleşme özelliklerini kullanılabilir gibi göstermemelidir. Gizlilik politikasının hazırlanması bu işlev eksikliğini gidermez.
