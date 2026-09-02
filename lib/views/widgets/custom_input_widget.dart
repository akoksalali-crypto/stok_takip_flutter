import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/stock_form_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/opencart_controller.dart';
import '../../utils/app_theme.dart';

class CustomInputWidget extends StatefulWidget {
  final String label;
  final String inputKey;
  final double width;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final bool buyukHarf;
  final bool isPassword;
  final FocusNode? focusNode;
  final TextEditingController? externalController;
  final Color? themeColor;
  final VoidCallback fiyatHesapla;
  final VoidCallback dovizGirislefiyatHesapla;
  final VoidCallback stokKaydet;

  const CustomInputWidget({
    super.key,
    required this.label,
    required this.inputKey,
    required this.width,
    this.onChanged,
    this.readOnly = false,
    this.buyukHarf = false,
    this.isPassword = false,
    this.focusNode,
    this.externalController,
    this.themeColor,
    required this.fiyatHesapla,
    required this.dovizGirislefiyatHesapla,
    required this.stokKaydet,
  });

  @override
  State<CustomInputWidget> createState() => _CustomInputWidgetState();
}

class _CustomInputWidgetState extends State<CustomInputWidget> {
  late final StockFormController stockFormController;
  late final SettingsController settingsController;
  late final OpenCartController openCartController;

  @override
  void initState() {
    super.initState();
    stockFormController = Get.find<StockFormController>();
    settingsController = Get.find<SettingsController>();
    openCartController = Get.find<OpenCartController>();
  }

  Widget? _buildSuffixIcon(String key, bool hasError, bool isMiktarEksi) {
    if (key == 'oc_pass') {
      return Obx(
        () => IconButton(
          icon: Icon(
            settingsController.isPasswordVisible.value
                ? Icons.visibility
                : Icons.visibility_off,
          ),
          onPressed: settingsController.togglePasswordVisibility,
        ),
      );
    }

    if (key.contains('barkod')) {
      return Obx(() {
        bool isSelected = stockFormController.basilacakBarkodKey.value == key;
        return IconButton(
          icon: Icon(
            isSelected ? Icons.check_circle : Icons.radio_button_off,
            color: isSelected ? Colors.green : Colors.grey,
          ),
          tooltip: "Basım için bu barkodu seç",
          onPressed: () {
            stockFormController.basilacakBarkodKey.value = key;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Yazdırılacak barkod seçildi: ${stockFormController.c[key]?.text}",
                ),
                duration: const Duration(milliseconds: 500),
              ),
            );
          },
        );
      });
    }

    if (key == 'metaTitle') return const Icon(Icons.copy, size: 22);
    if (key == 'alis') return const Icon(Icons.sell_outlined, size: 22);
    if (key == 'marj') return const Icon(Icons.margin, size: 22);
    if (key == 'satis') return const Icon(Icons.sell_rounded, size: 22);
    if (key == 'kdv') return const Icon(Icons.percent, size: 22);
    if (key == 'Fdate') {
      return const Icon(Icons.access_time, size: 22, color: Colors.blue);
    }
    if (key == 'Ldate') {
      return const Icon(Icons.timelapse, size: 22, color: Colors.blue);
    }
    if (key == 'metaDescription') return const Icon(Icons.mediation, size: 22);
    if (key == 'metaKeyword') return const Icon(Icons.key, size: 22);
    if (key == 'seoUrl') return const Icon(Icons.search_off, size: 22);
    if (key == 'miktar') {
      if (isMiktarEksi) return const Icon(Icons.warning, color: Colors.red);
      if (hasError) {
        return const Icon(Icons.error_outline, color: Colors.orange);
      }
      return const Icon(Icons.playlist_add_circle_outlined, size: 22);
    }
    if (key == 'weight') return const Icon(Icons.line_weight, size: 22);
    if (key == 'sabit_dolar' || key == 'parite_dolar_euro') {
      return const Icon(Icons.attach_money_sharp, size: 22);
    }
    if (key == 'parite_euro_dolar' || key == 'sabit_euro') {
      return const Icon(Icons.euro_symbol, size: 22);
    }
    if (key == 'kur_dolar') {
      return const Icon(
        Icons.attach_money_sharp,
        size: 22,
        color: Colors.orange,
      );
    }
    if (key == 'kur_euro') {
      return const Icon(
        Icons.euro_symbol_outlined,
        size: 22,
        color: Colors.orange,
      );
    }

    if (hasError) return const Icon(Icons.error_outline, color: Colors.orange);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      bool hasError = false;
      String? helper;

      final TextEditingController? activeController =
          widget.externalController ??
          stockFormController.c[widget.inputKey] ??
          settingsController.c[widget.inputKey];

      Color miktarRengi = Colors.black;
      bool isMiktarEksi = false;

      if (widget.inputKey == 'miktar') {
        double miktarDeger =
            double.tryParse(activeController?.text ?? '0') ?? 0;
        if (miktarDeger < 0) {
          miktarRengi = Colors.red.shade700;
          isMiktarEksi = true;
        } else if (miktarDeger > 0) {
          miktarRengi = Colors.green.shade700;
        }
      }

      if (openCartController.ocData.isNotEmpty) {
        if (widget.inputKey == 'satis') {
          double local =
              double.tryParse(
                activeController?.text.replaceAll(',', '.') ?? '0',
              ) ??
              0;
          double oc =
              double.tryParse(
                openCartController.ocData['price']?.toString() ?? '0',
              ) ??
              0;
          hasError = (local != oc);
          if (hasError) helper = "Web: $oc";
        } else if (widget.inputKey == 'miktar') {
          int local = int.tryParse(activeController?.text ?? '0') ?? 0;
          int oc =
              int.tryParse(
                openCartController.ocData['quantity']?.toString() ?? '0',
              ) ??
              0;
          hasError = (local != oc);
          if (hasError) helper = "Web: $oc";
        } else if (widget.inputKey == 'lot') {
          hasError =
              (activeController?.text !=
              openCartController.ocData['minimum']?.toString());
          if (hasError) {
            helper = "Web: ${openCartController.ocData['minimum']}";
          }
        } else if (widget.inputKey == 'weight') {
          double localA =
              double.tryParse(
                activeController?.text.replaceAll(',', '.') ?? '0',
              ) ??
              0;
          double ocA =
              double.tryParse(
                openCartController.ocData['weight']?.toString() ?? '0',
              ) ??
              0;
          hasError = (localA.toStringAsFixed(3) != ocA.toStringAsFixed(3));
          if (hasError) {
            helper = ocA < 1
                ? "Web: ${(ocA * 1000).toStringAsFixed(0)} gr"
                : "Web: ${ocA.toStringAsFixed(2)} kg";
          }
        }
      }

      Color borderSideColor = AppColors.borderLight;
      if (isMiktarEksi) {
        borderSideColor = AppColors.danger;
      } else if (hasError) {
        borderSideColor = AppColors.warning;
      } else if (widget.themeColor != null) {
        borderSideColor = widget.themeColor!;
      }

      return SizedBox(
        width: widget.width,
        child: GestureDetector(
          onLongPress: widget.inputKey == 'barkod'
              ? () =>
                    stockFormController.generateBarkodDialog()
              : null,
          onDoubleTap: () {
            if (widget.inputKey == 'metaTitle') {
              setState(() {
                activeController?.text =
                    stockFormController.c['stok_adi']?.text ?? "";
              });
            } else if (widget.inputKey == 'Ldate' ||
                widget.inputKey == 'Fdate') {
              setState(() {
                activeController?.text = DateTime.now().toString().split(
                  '.',
                )[0];
              });
              widget.stokKaydet();
            }
          },
          child: TextFormField(
            controller: activeController,
            focusNode: widget.focusNode,
            readOnly: widget.readOnly,
            obscureText:
                widget.isPassword &&
                !settingsController.isPasswordVisible.value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight:
                  (widget.inputKey == 'miktar' ||
                      widget.themeColor != null ||
                      hasError)
                  ? FontWeight.bold
                  : FontWeight.w600,
              color: widget.inputKey == 'miktar'
                  ? miktarRengi
                  : (widget.inputKey == 'satis'
                        ? miktarRengi
                        : AppColors.textPrimary),
            ),
            inputFormatters: widget.buyukHarf
                ? [
                    TextInputFormatter.withFunction(
                      (old, newValue) =>
                          newValue.copyWith(text: newValue.text.toUpperCase()),
                    ),
                  ]
                : [],
            textCapitalization: widget.buyukHarf
                ? TextCapitalization.characters
                : TextCapitalization.none,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (value) => FocusScope.of(context).nextFocus(),
            decoration: InputDecoration(
              labelText: widget.label,
              labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              filled: true,
              fillColor: isMiktarEksi
                  ? AppColors.danger.withValues(alpha: 0.05)
                  : (hasError
                      ? AppColors.warning.withValues(alpha: 0.08)
                      : (widget.readOnly ? AppColors.surfaceSubtle : Colors.white)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: borderSideColor,
                  width: (hasError || isMiktarEksi || widget.themeColor != null)
                      ? 1.5
                      : 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: widget.themeColor ?? AppColors.primary,
                  width: 1.8,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              helperText: helper,
              helperStyle: const TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              suffixIcon: _buildSuffixIcon(
                widget.inputKey,
                hasError,
                isMiktarEksi,
              ),
            ),
            onChanged: (value) {
              if (widget.inputKey == 'alis' ||
                  widget.inputKey == 'marj' ||
                  widget.inputKey == 'dolar_alis' ||
                  widget.inputKey == 'kur_dolar' ||
                  widget.inputKey == 'kur_euro' ||
                  widget.inputKey == 'sabit_dolar' ||
                  widget.inputKey == 'sabit_euro') {
                widget.fiyatHesapla();
              }
              setState(() {});
              if (widget.onChanged != null) widget.onChanged!(value);
            },
          ),
        ),
      );
    });
  }
}
