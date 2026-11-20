# Blue Serial Linux mağaza yayını

Bu depoda Ubuntu Uygulama Merkezi için Snap Store paketlemesi hazırlanmıştır. Paket adı `blue-serial`, masaüstü uygulama kimliği `com.ysfgrl.blue_serial` şeklindedir. Sürüm, `blue_serial/pubspec.yaml` dosyasından alınır; `1.0.0+1` için mağaza sürümü `1.0.0` olur. Yeni Snap yüklemelerine mağaza ayrıca revizyon numarası verir.

## Hazırlanan dosyalar

- [Snapcraft tanımı](../snap/snapcraft.yaml): Flutter release derlemesi, GNOME çalışma ortamı ve USB seri erişim izinleri.
- [Snap masaüstü kaydı](../snap/gui/blue-serial.desktop) ve aynı klasördeki simge.
- [Genel Linux masaüstü kaydı](../blue_serial/linux/packaging/com.ysfgrl.blue_serial.desktop): bağımsız Linux paketleri için ad, simge, kategori ve arama sözcükleri. Release bundle içinde `data/applications` ve `data/icons` altına kurulur.
- [GitHub Actions derlemesi](../.github/workflows/linux-snap.yml): elle başlatılır, `amd64` için `.snap` üretir ve indirilebilir artifact olarak saklar.

Snapcraft depo kökünden çalıştırılır. Uygulama `blue_serial/` altındadır; `blue_serial_lib` bağımlılığı `../` yolunu kullandığından derleme kaynağı tüm depoyu içerir. Yalnızca uygulama klasörünü göndermeyin.

## GitHub üzerinden paket oluşturma

1. Paketleme dosyalarını GitHub deposuna gönderin.
2. Deponun **Actions → Build Linux Snap → Run workflow** ekranından derlemeyi başlatın.
3. Başarılı çalışmanın **Artifacts** bölümünden `blue-serial-linux-amd64-snap` arşivini indirin.
4. Arşivden çıkan `.snap` dosyasını test cihazına kopyalayın.

Derleme iş akışı Snap Store hesabı veya mağaza anahtarı istemez; çıktıyı artifact olarak saklar. Mağaza yüklemesi aşağıdaki yayımlama adımında yapılır. Snapcraft komut satırından kurulur, LXD ortamı [Canonical Setup LXD](https://github.com/canonical/setup-lxd) eylemiyle hazırlanır. Derleme `snapcraft --use-lxd` komutuyla yapılır; JavaScript tabanlı checkout ve artifact yükleme adımları Node.js 24 kullanan sürümlere sabitlenmiştir.

## Yerelde paket oluşturma

Makinede Snapcraft ve LXD kurulu ve yapılandırılmış olmalıdır. Kurulum için [Flutter Linux yayımlama rehberindeki](https://docs.flutter.dev/deployment/linux) ortam hazırlama adımlarını izleyin. Ardından depo kökünde:

```sh
snapcraft --use-lxd
```

Yalnızca Flutter release dosyalarını üretmek için uygulama klasöründe `flutter build linux --release` çalıştırılabilir. Bu komut `.snap` oluşturmaz; çalıştırılabilir uygulamayı `build/linux/x64/release/bundle/` altında üretir. Bu klasördeki `data/` ve `lib/` dizinleri de uygulamanın parçasıdır.

## Kurulum ve USB seri erişimi

Üretilen dosyanın adı sürüme göre değişebilir. `1.0.0` sürümü ve `amd64` için:

```sh
sudo snap install ./blue-serial_1.0.0_amd64.snap --dangerous
sudo snap connect blue-serial:raw-usb
snap connections blue-serial
blue-serial
```

`--dangerous`, yalnızca yerel ve mağaza imzası olmayan paketi test etmek içindir. Mağazaya kabul edildikten sonra kullanıcılar `sudo snap install blue-serial` ile kurar.

Linux eklentisi `/sys/class/tty` ve `/proc/tty/drivers` üzerinden portları listeler, iletişim için `/dev/tty*` düğümlerini açar. Snap'in `raw-usb` arayüzü USB seri cihazları için `/dev/ttyUSB*`, `/dev/ttyACM*` ve sürücü listesine erişim sağlar; otomatik bağlanması varsayılmamalıdır. [snapd raw-usb uygulaması](https://github.com/canonical/snapd/blob/master/interfaces/builtin/raw_usb.go).

Bu Snap paketi USB seri adaptörleri hedefler. Dahili `/dev/ttyS*` portlarının bu izinle çalışacağı varsayılmaz. Bu portlar için `serial-port` slot bağlantısı ve ek doğrulama gerekebilir. `classic` veya `devmode` izinlerine otomatik geçilmez.

Snap arayüzünün bağlanması, kullanıcının normal Linux cihaz izinlerinin yerini almaz. Erişim reddedilirse cihazın grubunu `ls -l /dev/ttyUSB0` gibi bir komutla kontrol edin. Kullanıcı üyeliğini dağıtımınızın seri port erişim yönergelerine göre düzenleyin ve oturumu yeniden açın. Uygulamayı root olarak çalıştırmak veya cihaz izinlerini herkese açmak gerekmez.

## Snap Store hesabı ve yayın

[Snapcraft geliştirici panelinden](https://snapcraft.io/account) Ubuntu One hesabınızla giriş yapın. `blue-serial` adının uygunluğunu kontrol edin ve adın kaydını tamamlayın. Ad alınmışsa `snap/snapcraft.yaml` içindeki `name`, `apps` anahtarı ve Snap masaüstü kaydındaki adla ilgili yolları birlikte güncelleyin.

Snapcraft kurulu bir makinede hesabınıza giriş yaptıktan ve adı kaydettikten sonra, donanım testinden geçen paketi önce `candidate` kanalına yükleyin:

```sh
snapcraft login
snapcraft register blue-serial
snapcraft upload --release=candidate ./blue-serial_1.0.0_amd64.snap
```

Adı web panelinden kaydettiyseniz `register` komutunu tekrar çalıştırmanız gerekmez. İncelemeden geçen revizyonu ve test sonuçlarını kontrol ettikten sonra panelden `stable` kanalına alın. Snap Store otomatik kontroller yapar; arayüzler ve D-Bus adı için ek inceleme gerekebilir. [Flutter Snap Store yayımlama adımları](https://docs.flutter.dev/deployment/linux).

Mağaza sayfasında Blue Serial adını, Linux özelliklerini anlatan açıklamayı, Linux ekran görüntülerini, proje/destek adreslerini ve Linux sürümlerini de kapsayan [gizlilik politikasını](../PRIVACY_POLICY.md) kullanın. SSH, Bluetooth, bulut eşitleme veya desteklenmeyen bağlantıları mevcut özellik gibi göstermeyin.

## Yayımdan önce doğrulanacak davranış

Paketlenmiş uygulamayı gerçek USB seri cihazla açın. Port listesi, izin reddi, bağlanma/ayrılma, ASCII/HEX gönderimi, veri alımı, komut kaydetme ve yeniden açınca yükleme, günlük dışa aktarma ve panoya kopyalamayı deneyin. Özellikle USB cihazı açık bağlantı sırasında çıkarma davranışını kontrol edin. Arayüzün açılması tek başına USB erişimini doğrulamaz.

## Flathub seçeneği

Flathub için ayrı bir Flatpak manifesti, AppStream metadata, uygun uygulama kimliği ve Flatpak içindeki gerçek cihaz erişiminin doğrulanması gerekir. Bu depodaki Snap tanımı Flathub'a yüklenemez. Flutter bağımlılıklarının çevrimdışı derlemeye hazırlanması da ayrı bir adımdır. [Flathub başvuru gereklilikleri](https://docs.flathub.org/docs/for-app-authors/requirements).

## Bu ortamda doğrulananlar

Linux `x64` release derlemesi, masaüstü dosyalarının biçim kontrolü ve paylaşılan kütüphane denetimi tamamlanmıştır. Uygulama geçici ayar dizinleriyle yapılan sekiz saniyelik açılış kontrolünde çalışmaya devam etmiştir. Bu ortamda açılış sırasında XDG portal ayarı ve `FlValue` uyarıları gözlenmiştir; gerçek cihazla işlev testi ayrıca yapılmalıdır.

Snapcraft bu geliştirme ortamında kurulu olmadığından yerelde `.snap` derlemesi yapılmamıştır. Paket içindeki gerçek USB erişimi ayrıca doğrulanmalıdır. Node.js 24 için güncellenen GitHub Actions iş akışının uzak çalışması henüz doğrulanmamıştır.
