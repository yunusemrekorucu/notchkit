import SwiftUI
import Defaults
import LaunchAtLogin

struct SettingsView: View {
    @ObservedObject private var nav = SettingsNavigation.shared

    var body: some View {
        TabView(selection: $nav.tab) {
            GeneralSettings().tabItem { Label("Genel", systemImage: "gear") }.tag(SettingsTab.general)
            NookSettings().tabItem { Label("Nook", systemImage: "lamp.desk.fill") }.tag(SettingsTab.nook)
            WidgetsSettings().tabItem { Label("Widget'lar", systemImage: "square.grid.2x2.fill") }.tag(SettingsTab.widgets)
            TraySettings().tabItem { Label("Tepsi", systemImage: "tray.fill") }.tag(SettingsTab.tray)
            LiveActivitySettings().tabItem { Label("Canlı Aktiviteler", systemImage: "clock.badge.fill") }
                .tag(SettingsTab.liveActivities)
            AboutSettings().tabItem { Label("Hakkında", systemImage: "ellipsis.circle.fill") }.tag(SettingsTab.about)
        }
        .frame(minWidth: 620, minHeight: 520)
    }
}

private struct GeneralSettings: View {
    @Default(.alwaysOpenNotchOnHover) private var openOnHover
    @Default(.disableHaptics) private var disableHaptics
    @Default(.enableOnNonNotchScreens) private var nonNotch
    @Default(.preventUnhoverCloseWhenTyping) private var preventClose
    @Default(.preferRoundButtons) private var roundButtons
    @Default(.translucent) private var translucent
    @Default(.contentPadding) private var padding
    @Default(.notchWidthFineTune) private var widthTune
    @Default(.notchHeightFineTune) private var heightTune
    @Default(.horizontalSwipeChangesTrack) private var swipeTrack

    var body: some View {
        Form {
            Section {
                LaunchAtLogin.Toggle("Girişte başlat")
                Toggle("Üzerine gelince her zaman aç", isOn: $openOnHover)
                    .help("Açıkken bazı hareketler devre dışı kalır.")
                Toggle("Haptik geri bildirimi kapat", isOn: $disableHaptics)
                Toggle("Yazarken fare çıkınca kapanmasın", isOn: $preventClose)
                Toggle("Notch'suz ekranlarda da etkinleştir", isOn: $nonNotch)
                Toggle("Yatay kaydırmayla parça değiştir", isOn: $swipeTrack)
            }
            Section("Görünüm") {
                Toggle("Yuvarlak butonları tercih et", isOn: $roundButtons)
                Toggle("Yarı saydam notch arka planı", isOn: $translucent)
                ValueStepper("İçerik boşluğu", value: $padding, in: 4...24, display: "\(padding) pt")
            }
            Section {
                Slider(value: $widthTune, in: -20...20, step: 1) { Text("Genişlik: \(Int(widthTune))") }
                Slider(value: $heightTune, in: -10...10, step: 1) { Text("Yükseklik: \(Int(heightTune))") }
                Button("Sıfırla") { widthTune = 0; heightTune = 0 }
            } header: {
                Text("Notch ince ayarı")
            } footer: {
                Text("Nook notch boyutunu otomatik algılar. Kenarlarda boşluk kalıyorsa buradan düzeltin.")
            }
        }
        .formStyle(.grouped)
    }
}

private struct NookSettings: View {
    @Default(.nookEnabled) private var enabled
    @Default(.nookHeight) private var height
    @Default(.cellSize) private var cellSize
    @Default(.widgetsPadding) private var spacing
    @Default(.nookShowDividers) private var dividers

    var body: some View {
        Form {
            Section {
                Toggle("Nook'u etkinleştir", isOn: $enabled)
            } footer: {
                Text("Kapalıyken notch'a tıklamak bir şey yapmaz.")
            }
            Section {
                ValueStepper("Yükseklik", value: $height, in: 1...4, display: "\(height) hücre")
                ValueStepper("Hücre boyutu", value: $cellSize, in: 40...80, step: 2, display: "\(cellSize) pt")
                ValueStepper("Widget aralığı", value: $spacing, in: 4...20, display: "\(spacing) pt")
                Toggle("Widget'lar arasında ayraç göster", isOn: $dividers)
            } header: {
                Text("Yerleşim")
            } footer: {
                Text("Genişlik, Widget'lar sekmesindeki widget'lara göre otomatik hesaplanır.")
            }
            Section {
                Button("Widget'ları düzenle…") { SettingsNavigation.shared.tab = .widgets }
            }
        }
        .formStyle(.grouped)
    }
}

private struct TraySettings: View {
    @Default(.trayWidth) private var width
    @Default(.trayHeight) private var height
    @ObservedObject private var tray = TrayStore.shared

    var body: some View {
        Form {
            Section("Boyut") {
                ValueStepper("Genişlik", value: $width, in: 6...20, display: "\(width) hücre")
                ValueStepper("Yükseklik", value: $height, in: 1...4, display: "\(height) hücre")
            }
            Section("Dosyalar") {
                LabeledContent("Tepsideki dosya", value: "\(tray.items.count)")
                Button("Tepsiyi temizle", role: .destructive) { tray.removeAll() }.disabled(tray.items.isEmpty)
            }
        }
        .formStyle(.grouped)
    }
}

private struct LiveActivitySettings: View {
    @Default(.liveActivitiesEnabled) private var enabled
    @Default(.enabledLiveActivities) private var activities
    @Default(.enableQuickPeek) private var quickPeek
    @Default(.coloredEffects) private var colored

    var body: some View {
        Form {
            Section {
                Toggle("Canlı aktiviteleri etkinleştir", isOn: $enabled)
                Toggle("Şarkı değişince hızlı bakış göster", isOn: $quickPeek)
            }
            Section("Aktiviteler") {
                ForEach(LiveActivityToggle.allCases) { a in
                    Toggle(a.title, isOn: Binding(
                        get: { activities.contains(a) },
                        set: { on in if on { activities.append(a) } else { activities.removeAll { $0 == a } } }))
                }
            }
            Section("Medya") {
                Toggle("Albüm rengini kullan", isOn: $colored)
            }
        }
        .formStyle(.grouped)
    }
}

private struct AboutSettings: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 96, height: 96)
            Text("Nook").font(.largeTitle.bold())
            Text("Sürüm \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .foregroundStyle(.secondary)
            Text("Müzik, notlar, görevler ve dosyalar. Notch'unun tam içinde.")
                .multilineTextAlignment(.center).foregroundStyle(.secondary)
            Text("Medya: mediaremote-adapter (BSD-3, © Jonas van den Berg)")
                .font(.caption).foregroundStyle(.tertiary)
            Button("Nook'tan çık") { NSApp.terminate(nil) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
