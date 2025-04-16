import 'package:flutter/foundation.dart';
import 'package:stackfood_multivendor_restaurant/common/widgets/custom_app_bar_widget.dart';
import 'package:stackfood_multivendor_restaurant/common/widgets/custom_text_field_widget.dart';
import 'package:stackfood_multivendor_restaurant/common/models/config_model.dart';
import 'package:stackfood_multivendor_restaurant/features/restaurant/controllers/restaurant_controller.dart';
import 'package:stackfood_multivendor_restaurant/features/restaurant/domain/models/product_model.dart';
import 'package:stackfood_multivendor_restaurant/features/addon/controllers/addon_controller.dart';
import 'package:stackfood_multivendor_restaurant/features/splash/controllers/splash_controller.dart';
import 'package:stackfood_multivendor_restaurant/helper/custom_print_helper.dart';
import 'package:stackfood_multivendor_restaurant/util/dimensions.dart';
import 'package:stackfood_multivendor_restaurant/common/widgets/custom_button_widget.dart';
import 'package:stackfood_multivendor_restaurant/common/widgets/custom_snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackfood_multivendor_restaurant/util/styles.dart';

class AddAddonScreen extends StatefulWidget {
  final AddOns? addon;
  const AddAddonScreen({super.key, this.addon});

  @override
  State<AddAddonScreen> createState() => _AddAddonScreenState();
}

class _AddAddonScreenState extends State<AddAddonScreen> with TickerProviderStateMixin {

  final List<TextEditingController> _nameControllers = [];
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockTextController = TextEditingController();
  final List<FocusNode> _nameNodes = [];
  final FocusNode _priceNode = FocusNode();
  final List<Language>? _languageList = Get.find<SplashController>().configModel!.language;
  TabController? _tabController;
  final List<Tab> _tabs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _languageList!.length, initialIndex: 0, vsync: this);
    for (var language in _languageList) {
      if (kDebugMode) {
        print(language);
      }
      _nameControllers.add(TextEditingController());
      _nameNodes.add(FocusNode());
    }

    if(widget.addon != null) {
      for(int index=0; index<_languageList.length; index++) {
        _nameControllers.add(TextEditingController(text: widget.addon!.translations![widget.addon!.translations!.length-1].value));
        _nameNodes.add(FocusNode());
        for(Translation translation in widget.addon!.translations!) {
          if(_languageList[index].key == translation.locale && translation.key == 'name') {
            _nameControllers[index] = TextEditingController(text: translation.value);
            break;
          }
        }
      }
      _priceController.text = widget.addon!.price.toString();
    }else {
      for (var language in _languageList) {
        _nameControllers.add(TextEditingController());
        _nameNodes.add(FocusNode());
        customPrint(language);
      }
    }

    for (var language in _languageList) {
      _tabs.add(Tab(text: language.value));
    }

    _stockTextController.text = widget.addon?.addonStock == 0 ? '' : widget.addon?.addonStock!.toString() ?? '';
    _setStockType(widget.addon?.stockType);

  }

  void _setStockType(String? type) {
    if(type == 'limited') {
      Get.find<RestaurantController>().setStockTypeIndex(1, false);
    } else if (type == 'daily') {
      Get.find<RestaurantController>().setStockTypeIndex(2, false);
    } else {
      Get.find<RestaurantController>().setStockTypeIndex(0, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: widget.addon != null ? 'update_addon'.tr : 'add_new_addons'.tr),

      body: GetBuilder<RestaurantController>(builder: (restaurantController) {
        return GetBuilder<AddonController>(builder: (addonController) {
          return Column(children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Column(children: [

                  Container(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 1, blurRadius: 1, offset: const Offset(0, 1))],
                    ),
                    child: Column(children: [

                      SizedBox(
                        height: 40,
                        child: TabBar(
                          tabAlignment: TabAlignment.start,
                          controller: _tabController,
                          indicatorColor: Theme.of(context).primaryColor,
                          indicatorWeight: 3,
                          labelColor: Theme.of(context).primaryColor,
                          unselectedLabelColor: Theme.of(context).disabledColor,
                          unselectedLabelStyle: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
                          labelStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                          labelPadding: const EdgeInsets.only(right: Dimensions.paddingSizeLarge),
                          indicatorPadding: const EdgeInsets.only(right: Dimensions.paddingSizeLarge),
                          isScrollable: true,
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          tabs: _tabs,
                          onTap: (int ? value) {
                            setState(() {});
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
                        child: Divider(height: 0),
                      ),

                      CustomTextFieldWidget(
                        hintText: '${'name'.tr} (${_languageList?[_tabController!.index].value}) *',
                        labelText: 'name'.tr,
                        controller: _nameControllers[_tabController!.index],
                        focusNode: _nameNodes[_tabController!.index],
                        nextFocus: _tabController!.index != _languageList!.length-1 ? _priceNode : _priceNode,
                        inputType: TextInputType.name,
                        capitalization: TextCapitalization.words,
                        showTitle: false,
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                      CustomTextFieldWidget(
                        hintText: '${'price'.tr} (${Get.find<SplashController>().configModel?.currencySymbol})',
                        labelText: '${'price'.tr} (${Get.find<SplashController>().configModel?.currencySymbol})',
                        controller: _priceController,
                        focusNode: _priceNode,
                        inputAction: TextInputAction.done,
                        inputType: TextInputType.number,
                        isAmount: true,
                        showTitle: false,
                        isRequired: true,
                      ),
                    ]),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  Container(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 1, blurRadius: 1, offset: const Offset(0, 1))],
                    ),
                    child: Column(children: [

                      Stack(clipBehavior: Clip.none, children: [

                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          ),
                          child: Row(children: [

                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  restaurantController.setStockTypeIndex(0, true);
                                },
                                child: Row(children: [
                                  Radio(
                                    value: 0,
                                    groupValue: restaurantController.stockTypeIndex,
                                    onChanged: (int? value) {
                                      restaurantController.setStockTypeIndex(value!, true);
                                    },
                                    activeColor: Theme.of(context).primaryColor,
                                  ),
                                  Text('unlimited'.tr, style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color)),
                                ]),
                              ),
                            ),

                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  restaurantController.setStockTypeIndex(1, true);
                                },
                                child: Row(children: [
                                  Radio(
                                    value: 1,
                                    groupValue: restaurantController.stockTypeIndex,
                                    onChanged: (int? value) {
                                      restaurantController.setStockTypeIndex(value!, true);
                                    },
                                    activeColor: Theme.of(context).primaryColor,
                                  ),
                                  Text('limited'.tr, style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color)),
                                ]),
                              ),
                            ),

                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  restaurantController.setStockTypeIndex(2, true);
                                },
                                child: Row(children: [
                                  Radio(
                                    value: 2,
                                    groupValue: restaurantController.stockTypeIndex,
                                    onChanged: (int? value) {
                                      restaurantController.setStockTypeIndex(value!, true);
                                    },
                                    activeColor: Theme.of(context).primaryColor,
                                  ),
                                  Text('daily'.tr, style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color)),
                                ]),
                              ),
                            ),

                          ]),
                        ),

                        Positioned(
                          left: 10, top: -15,
                          child: Container(
                            decoration: BoxDecoration(color: Theme.of(context).cardColor),
                            padding: const EdgeInsets.all(5),
                            child: Row(
                              children: [
                                Text('stock_type'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall)),
                                Text(' *', style: robotoRegular.copyWith(color: Theme.of(context).colorScheme.error, fontSize: Dimensions.fontSizeSmall)),
                              ],
                            ),
                          ),
                        ),

                      ]),
                      SizedBox(height: restaurantController.stockTypeIndex == 0 || (restaurantController.stockTextFieldDisable) ? 0 : Dimensions.paddingSizeExtraLarge),

                      restaurantController.stockTypeIndex == 0 || (restaurantController.stockTextFieldDisable) ? const SizedBox() : CustomTextFieldWidget(
                        hintText: restaurantController.stockTypeIndex == 0 ? 'unlimited'.tr : 'eg_18'.tr,
                        labelText: restaurantController.stockTypeIndex == 0 ? 'unlimited'.tr : restaurantController.stockTypeIndex == 0 ? 'limited_stock'.tr : 'daily_stock'.tr,
                        controller: _stockTextController,
                        inputAction: TextInputAction.done,
                        inputType: TextInputType.phone,
                        showTitle: false,
                        readOnly: restaurantController.stockTypeIndex == 0 || (restaurantController.stockTextFieldDisable) ? true : false,
                      ),

                    ]),
                  ),

                ]),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 1, blurRadius: 1, offset: const Offset(0, 1))],
              ),
              child: !addonController.isLoading ? CustomButtonWidget(
                onPressed: () {

                  String name = _nameControllers[0].text.trim();
                  String price = _priceController.text.trim();

                  int addonStock = 0;
                  try{
                    addonStock = int.parse(_stockTextController.text.trim());
                  } catch(e) {
                    addonStock = 0;
                  }

                  if(name.isEmpty) {
                    showCustomSnackBar('enter_addon_name'.tr);
                  }else if(price.isEmpty) {
                    showCustomSnackBar('enter_addon_price'.tr);
                  }else if(_stockTextController.text.isEmpty && restaurantController.stockTypeIndex != 0){
                    showCustomSnackBar('enter_the_addon_stock'.tr);
                  }else {
                    List<Translation> nameList = [];
                    for(int index=0; index<_languageList.length; index++) {
                      nameList.add(Translation(
                        locale: _languageList[index].key, key: 'name',
                        value: _nameControllers[index].text.trim().isNotEmpty ? _nameControllers[index].text.trim()
                            : _nameControllers[0].text.trim(),
                      ));
                    }

                    AddOns addon = AddOns(
                      name: name, price: double.parse(price), translations: nameList,
                      addonStock: addonStock == 0 ? null : addonStock,
                      stockType: restaurantController.stockTypeIndex == 0 ? 'unlimited' : restaurantController.stockTypeIndex == 1 ? 'limited' : 'daily',
                    );

                    if(widget.addon != null) {
                      addon.id = widget.addon!.id;
                      addonController.updateAddon(addon);
                    }else {
                      addonController.addAddon(addon);
                    }
                  }
                },
                buttonText: widget.addon != null ? 'update'.tr : 'submit'.tr,
              ) : const Center(child: CircularProgressIndicator())
            ),
          ]);
        });
      }),
    );
  }
}
