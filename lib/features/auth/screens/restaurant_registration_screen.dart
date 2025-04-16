import 'dart:convert';
import 'dart:io';
import 'package:card_swiper/card_swiper.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:stackfood_multivendor_restaurant/common/widgets/confirmation_dialog_widget.dart';
import 'package:stackfood_multivendor_restaurant/common/widgets/custom_app_bar_widget.dart';
import 'package:stackfood_multivendor_restaurant/common/widgets/custom_button_widget.dart';
import 'package:stackfood_multivendor_restaurant/common/widgets/custom_snackbar_widget.dart';
import 'package:stackfood_multivendor_restaurant/common/widgets/custom_text_field_widget.dart';
import 'package:stackfood_multivendor_restaurant/features/auth/controllers/auth_controller.dart';
import 'package:stackfood_multivendor_restaurant/features/auth/controllers/location_controller.dart';
import 'package:stackfood_multivendor_restaurant/features/business/domain/models/package_model.dart';
import 'package:stackfood_multivendor_restaurant/features/business/widgets/base_card_widget.dart';
import 'package:stackfood_multivendor_restaurant/features/business/widgets/package_card_widget.dart';
import 'package:stackfood_multivendor_restaurant/features/language/controllers/localization_controller.dart';
import 'package:stackfood_multivendor_restaurant/common/models/config_model.dart';
import 'package:stackfood_multivendor_restaurant/features/restaurant/controllers/restaurant_controller.dart';
import 'package:stackfood_multivendor_restaurant/features/restaurant/domain/models/product_model.dart';
import 'package:stackfood_multivendor_restaurant/features/auth/domain/models/restaurant_body_model.dart';
import 'package:stackfood_multivendor_restaurant/features/auth/widgets/additional_data_section_widget.dart';
import 'package:stackfood_multivendor_restaurant/features/auth/widgets/custom_time_picker_widget.dart';
import 'package:stackfood_multivendor_restaurant/features/auth/widgets/pass_view_widget.dart';
import 'package:stackfood_multivendor_restaurant/features/auth/widgets/select_location_view_widget.dart';
import 'package:stackfood_multivendor_restaurant/features/splash/controllers/splash_controller.dart';
import 'package:stackfood_multivendor_restaurant/helper/responsive_helper.dart';
import 'package:stackfood_multivendor_restaurant/helper/route_helper.dart';
import 'package:stackfood_multivendor_restaurant/util/dimensions.dart';
import 'package:stackfood_multivendor_restaurant/util/images.dart';
import 'package:stackfood_multivendor_restaurant/util/styles.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RestaurantRegistrationScreen extends StatefulWidget {
  const RestaurantRegistrationScreen({super.key});

  @override
  State<RestaurantRegistrationScreen> createState() =>
      _RestaurantRegistrationScreenState();
}

class _RestaurantRegistrationScreenState
    extends State<RestaurantRegistrationScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final List<TextEditingController> _nameController = [];
  final List<TextEditingController> _addressController = [];
  final TextEditingController _vatController = TextEditingController();
  final TextEditingController _fNameController = TextEditingController();
  final TextEditingController _lNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  TextEditingController _c = TextEditingController();
  final List<FocusNode> _nameFocus = [];
  final List<FocusNode> _addressFocus = [];
  final FocusNode _vatFocus = FocusNode();
  final FocusNode _fNameFocus = FocusNode();
  final FocusNode _lNameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  bool firstTime = true;
  TabController? _tabController;
  final List<Tab> _tabs = [];

  final List<Language>? _languageList =
      Get.find<SplashController>().configModel!.language;
  String? _countryDialCode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: _languageList!.length, initialIndex: 0, vsync: this);
    _countryDialCode = CountryCode.fromCountryCode(
            Get.find<SplashController>().configModel!.country!)
        .dialCode;
    for (var language in _languageList) {
      if (kDebugMode) {
        print(language);
      }
      _nameController.add(TextEditingController());
      _addressController.add(TextEditingController());
      _nameFocus.add(FocusNode());
      _addressFocus.add(FocusNode());
    }

    for (var language in _languageList) {
      _tabs.add(Tab(text: language.value));
    }

    Get.find<AuthController>().pickImageForRegistration(false, true);
    Get.find<AuthController>().setJoinUsPageData(willUpdate: false);
    Get.find<AuthController>().storeStatusChange(0.1, willUpdate: false);
    Get.find<RestaurantController>().getCuisineList();
    Get.find<LocationController>().getZoneList();
    Get.find<AuthController>().resetBusiness();
    Get.find<AuthController>().getPackageList(isUpdate: false);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(builder: (authController) {
      return GetBuilder<LocationController>(builder: (locationController) {
        return GetBuilder<RestaurantController>(
            builder: (restaurantController) {
          if (locationController.storeAddress != null &&
              _languageList!.isNotEmpty) {
            _addressController[0].text =
                locationController.storeAddress.toString();
          }
          List<int> cuisines = [];
          if (restaurantController.cuisineModel != null) {
            for (int index = 0;
                index < restaurantController.cuisineModel!.cuisines!.length;
                index++) {
              if (restaurantController.cuisineModel!.cuisines![index].status ==
                      1 &&
                  !restaurantController.selectedCuisines!.contains(index)) {
                cuisines.add(index);
              }
            }
          }

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (authController.storeStatus == 0.6 && firstTime) {
                authController.storeStatusChange(0.1);
                firstTime = false;
              } else if (authController.storeStatus == 0.9) {
                authController.storeStatusChange(0.6);
              } else {
                await _showBackPressedDialogue(
                    'your_registration_not_setup_yet'.tr);
              }
            },
            child: Scaffold(
              appBar: CustomAppBarWidget(
                  title: 'restaurant_application'.tr,
                  onBackPressed: () async {
                    if (authController.storeStatus == 0.6 && firstTime) {
                      authController.storeStatusChange(0.1);
                      firstTime = false;
                    } else if (authController.storeStatus == 0.9) {
                      authController.storeStatusChange(0.6);
                    } else {
                      await _showBackPressedDialogue(
                          'your_registration_not_setup_yet'.tr);
                    }
                  }),
              body: SafeArea(
                child: Center(
                    child: SizedBox(
                  width: context.width,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeLarge,
                              vertical: Dimensions.paddingSizeSmall),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authController.storeStatus == 0.1
                                      ? 'provide_restaurant_information_to_proceed_next'
                                          .tr
                                      : authController.storeStatus == 0.6
                                          ? 'provide_owner_information_to_confirm'
                                              .tr
                                          : 'you_are_one_step_away_choose_your_business_plan'
                                              .tr,
                                  style: robotoRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: Theme.of(context).hintColor),
                                ),
                                const SizedBox(
                                    height: Dimensions.paddingSizeSmall),
                                LinearProgressIndicator(
                                  backgroundColor:
                                      Theme.of(context).disabledColor,
                                  minHeight: 2,
                                  value: authController.storeStatus,
                                ),
                              ]),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                                vertical: Dimensions.paddingSizeSmall,
                                horizontal: Dimensions.paddingSizeDefault),
                            child: SizedBox(
                              width: Dimensions.webMaxWidth,
                              child: Column(children: [
                                Visibility(
                                  visible: authController.storeStatus == 0.1,
                                  child: Column(children: [
                                    Row(children: [
                                      Expanded(
                                          flex: 4,
                                          child: Align(
                                              alignment: Alignment.center,
                                              child: Stack(children: [
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                      Dimensions
                                                          .paddingSizeExtraSmall),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            Dimensions
                                                                .radiusSmall),
                                                    child: authController
                                                                .pickedLogo !=
                                                            null
                                                        ? GetPlatform.isWeb
                                                            ? Image.network(
                                                                authController
                                                                    .pickedLogo!
                                                                    .path,
                                                                width: 150,
                                                                height: 120,
                                                                fit: BoxFit
                                                                    .cover,
                                                              )
                                                            : Image.file(
                                                                File(authController
                                                                    .pickedLogo!
                                                                    .path),
                                                                width: 150,
                                                                height: 120,
                                                                fit: BoxFit
                                                                    .cover,
                                                              )
                                                        : SizedBox(
                                                            width: 150,
                                                            height: 120,
                                                            child: Column(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Icon(
                                                                      Icons
                                                                          .camera_alt,
                                                                      size: 38,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .disabledColor),
                                                                  const SizedBox(
                                                                      height: Dimensions
                                                                          .paddingSizeSmall),
                                                                  Text(
                                                                    'select_restaurant_logo'
                                                                        .tr,
                                                                    style: robotoRegular.copyWith(
                                                                        color: Theme.of(context)
                                                                            .disabledColor,
                                                                        fontSize:
                                                                            Dimensions.fontSizeSmall),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                  ),
                                                                ]),
                                                          ),
                                                  ),
                                                ),
                                                Positioned(
                                                  bottom: 0,
                                                  right: 0,
                                                  top: 0,
                                                  left: 0,
                                                  child: InkWell(
                                                    onTap: () => authController
                                                        .pickImageForRegistration(
                                                            true, false),
                                                    child: DottedBorder(
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                      strokeWidth: 1,
                                                      strokeCap: StrokeCap.butt,
                                                      dashPattern: const [5, 5],
                                                      padding:
                                                          const EdgeInsets.all(
                                                              0),
                                                      borderType:
                                                          BorderType.RRect,
                                                      radius: const Radius
                                                          .circular(Dimensions
                                                              .radiusDefault),
                                                      child: Center(
                                                        child: Visibility(
                                                          visible: authController
                                                                  .pickedLogo !=
                                                              null,
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(25),
                                                            decoration:
                                                                BoxDecoration(
                                                              border: Border.all(
                                                                  width: 2,
                                                                  color: Colors
                                                                      .white),
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            child: const Icon(
                                                                Icons
                                                                    .camera_alt,
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ]))),
                                      const SizedBox(
                                          width: Dimensions.paddingSizeSmall),
                                      Expanded(
                                          flex: 6,
                                          child: Stack(children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(5.0),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        Dimensions.radiusSmall),
                                                child: authController
                                                            .pickedCover !=
                                                        null
                                                    ? GetPlatform.isWeb
                                                        ? Image.network(
                                                            authController
                                                                .pickedCover!
                                                                .path,
                                                            width:
                                                                context.width,
                                                            height: 120,
                                                            fit: BoxFit.cover,
                                                          )
                                                        : Image.file(
                                                            File(authController
                                                                .pickedCover!
                                                                .path),
                                                            width:
                                                                context.width,
                                                            height: 120,
                                                            fit: BoxFit.cover,
                                                          )
                                                    : SizedBox(
                                                        width: context.width,
                                                        height: 120,
                                                        child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                  Icons
                                                                      .camera_alt,
                                                                  size: 38,
                                                                  color: Theme.of(
                                                                          context)
                                                                      .disabledColor),
                                                              const SizedBox(
                                                                  height: Dimensions
                                                                      .paddingSizeSmall),
                                                              Text(
                                                                'select_restaurant_cover_photo'
                                                                    .tr,
                                                                style: robotoRegular.copyWith(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .disabledColor,
                                                                    fontSize:
                                                                        Dimensions
                                                                            .fontSizeSmall),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ]),
                                                      ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              top: 0,
                                              left: 0,
                                              child: InkWell(
                                                onTap: () => authController
                                                    .pickImageForRegistration(
                                                        false, false),
                                                child: DottedBorder(
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                  strokeWidth: 1,
                                                  strokeCap: StrokeCap.butt,
                                                  dashPattern: const [5, 5],
                                                  padding:
                                                      const EdgeInsets.all(0),
                                                  borderType: BorderType.RRect,
                                                  radius: const Radius.circular(
                                                      Dimensions.radiusDefault),
                                                  child: Center(
                                                    child: Visibility(
                                                      visible: authController
                                                              .pickedCover !=
                                                          null,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(25),
                                                        decoration:
                                                            BoxDecoration(
                                                          border: Border.all(
                                                              width: 3,
                                                              color:
                                                                  Colors.white),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                            Icons.camera_alt,
                                                            color: Colors.white,
                                                            size: 50),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ])),
                                    ]),
                                    const SizedBox(
                                        height:
                                            Dimensions.paddingSizeExtraLarge),
                                    SizedBox(
                                      height: 40,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: TabBar(
                                          tabAlignment: TabAlignment.start,
                                          controller: _tabController,
                                          indicatorColor:
                                              Theme.of(context).primaryColor,
                                          indicatorWeight: 3,
                                          labelColor:
                                              Theme.of(context).primaryColor,
                                          unselectedLabelColor:
                                              Theme.of(context).disabledColor,
                                          unselectedLabelStyle:
                                              robotoRegular.copyWith(
                                                  color: Theme.of(context)
                                                      .disabledColor,
                                                  fontSize:
                                                      Dimensions.fontSizeSmall),
                                          labelStyle: robotoBold.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeDefault,
                                              color: Theme.of(context)
                                                  .primaryColor),
                                          labelPadding: const EdgeInsets.only(
                                              right: Dimensions.radiusDefault),
                                          isScrollable: true,
                                          indicatorSize:
                                              TabBarIndicatorSize.tab,
                                          tabs: _tabs,
                                          dividerColor: Colors.transparent,
                                          onTap: (int? value) {
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(
                                          bottom: Dimensions.paddingSizeLarge),
                                      child: Divider(height: 0),
                                    ),
                                    CustomTextFieldWidget(
                                      hintText:
                                          '${'restaurant_name'.tr} (${_languageList?[_tabController!.index].value!})',
                                      labelText:
                                          '${'restaurant_name'.tr} (${_languageList?[_tabController!.index].value!})',
                                      controller: _nameController[
                                          _tabController!.index],
                                      focusNode:
                                          _nameFocus[_tabController!.index],
                                      nextFocus: _tabController!.index !=
                                              _languageList!.length - 1
                                          ? _addressFocus[_tabController!.index]
                                          : _addressFocus[0],
                                      inputType: TextInputType.name,
                                      capitalization: TextCapitalization.words,
                                      required: true,
                                    ),
                                    const SizedBox(
                                        height: Dimensions.paddingSizeLarge),
                                    locationController.zoneList != null
                                        ? const SelectLocationViewWidget(
                                            fromView: true)
                                        : const Center(
                                            child: CircularProgressIndicator()),
                                    const SizedBox(
                                        height: Dimensions.paddingSizeLarge),
                                    CustomTextFieldWidget(
                                      hintText: 'enter_restaurant_address'.tr,
                                      labelText: 'address'.tr,
                                      controller: _addressController[0],
                                      focusNode: _addressFocus[0],
                                      inputAction: TextInputAction.done,
                                      inputType: TextInputType.text,
                                      capitalization:
                                          TextCapitalization.sentences,
                                      maxLines: 3,
                                      required: true,
                                    ),
                                    const SizedBox(
                                        height: Dimensions.paddingSizeLarge),
                                    CustomTextFieldWidget(
                                      hintText: 'vat_tax'.tr,
                                      labelText: 'vat_tax'.tr,
                                      controller: _vatController,
                                      focusNode: _vatFocus,
                                      inputAction: TextInputAction.done,
                                      inputType: TextInputType.number,
                                      isAmount: true,
                                    ),
                                    const SizedBox(
                                        height:
                                            Dimensions.paddingSizeExtraLarge),
                                    Column(children: [
                                      Autocomplete<int>(
                                        optionsBuilder:
                                            (TextEditingValue value) {
                                          if (value.text.isEmpty) {
                                            return const Iterable<int>.empty();
                                          } else {
                                            return cuisines.where((cuisine) =>
                                                restaurantController
                                                    .cuisineModel!
                                                    .cuisines![cuisine]
                                                    .name!
                                                    .toLowerCase()
                                                    .contains(value.text
                                                        .toLowerCase()));
                                          }
                                        },
                                        fieldViewBuilder: (context, controller,
                                            node, onComplete) {
                                          _c = controller;
                                          return Container(
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color:
                                                  Theme.of(context).cardColor,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      Dimensions.radiusSmall),
                                            ),
                                            child: TextField(
                                              controller: controller,
                                              focusNode: node,
                                              textInputAction:
                                                  TextInputAction.done,
                                              onEditingComplete: () {
                                                onComplete();
                                                controller.text = '';
                                              },
                                              decoration: InputDecoration(
                                                hintText: 'cuisines'.tr,
                                                hintStyle:
                                                    robotoRegular.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeDefault,
                                                        color: Theme.of(context)
                                                            .hintColor),
                                                labelText: 'cuisines'.tr,
                                                labelStyle:
                                                    robotoRegular.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeDefault,
                                                        color: Theme.of(context)
                                                            .hintColor),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          Dimensions
                                                              .radiusDefault),
                                                  borderSide: BorderSide(
                                                      style: BorderStyle.solid,
                                                      width: 1,
                                                      color: Theme.of(context)
                                                          .disabledColor
                                                          .withValues(
                                                              alpha: 0.5)),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          Dimensions
                                                              .radiusDefault),
                                                  borderSide: BorderSide(
                                                      style: BorderStyle.solid,
                                                      width: 1,
                                                      color: Theme.of(context)
                                                          .disabledColor
                                                          .withValues(
                                                              alpha: 0.5)),
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          Dimensions
                                                              .radiusDefault),
                                                  borderSide: BorderSide(
                                                      style: BorderStyle.solid,
                                                      width: 1,
                                                      color: Theme.of(context)
                                                          .disabledColor
                                                          .withValues(
                                                              alpha: 0.5)),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        optionsViewBuilder: (context,
                                            Function(int i) onSelected, data) {
                                          return Align(
                                            alignment: Alignment.topLeft,
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                  maxWidth:
                                                      context.width * 0.4),
                                              child: ListView.builder(
                                                itemCount: data.length,
                                                padding: EdgeInsets.zero,
                                                shrinkWrap: true,
                                                itemBuilder: (context, index) =>
                                                    Material(
                                                  child: InkWell(
                                                    onTap: () => onSelected(
                                                        data.elementAt(index)),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                          color:
                                                              Theme.of(context)
                                                                  .cardColor),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: Dimensions
                                                              .paddingSizeSmall,
                                                          horizontal: Dimensions
                                                              .paddingSizeExtraSmall),
                                                      child: Text(
                                                          restaurantController
                                                                  .cuisineModel!
                                                                  .cuisines![data
                                                                      .elementAt(
                                                                          index)]
                                                                  .name ??
                                                              ''),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        displayStringForOption: (value) =>
                                            restaurantController.cuisineModel!
                                                .cuisines![value].name!,
                                        onSelected: (int value) {
                                          _c.text = '';
                                          restaurantController
                                              .setSelectedCuisineIndex(
                                                  value, true);
                                        },
                                      ),
                                      SizedBox(
                                          height: restaurantController
                                                  .selectedCuisines!.isNotEmpty
                                              ? Dimensions.paddingSizeSmall
                                              : 0),
                                      SizedBox(
                                        height: restaurantController
                                                .selectedCuisines!.isNotEmpty
                                            ? 40
                                            : 0,
                                        child: ListView.builder(
                                          itemCount: restaurantController
                                              .selectedCuisines!.length,
                                          scrollDirection: Axis.horizontal,
                                          itemBuilder: (context, index) {
                                            return Container(
                                              padding: const EdgeInsets.only(
                                                  left: Dimensions
                                                      .paddingSizeExtraSmall),
                                              margin: const EdgeInsets.only(
                                                  right: Dimensions
                                                      .paddingSizeSmall),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        Dimensions.radiusSmall),
                                              ),
                                              child: Row(children: [
                                                Text(
                                                  restaurantController
                                                      .cuisineModel!
                                                      .cuisines![
                                                          restaurantController
                                                                  .selectedCuisines![
                                                              index]]
                                                      .name!,
                                                  style: robotoRegular.copyWith(
                                                      color: Theme.of(context)
                                                          .cardColor),
                                                ),
                                                InkWell(
                                                  onTap: () =>
                                                      restaurantController
                                                          .removeCuisine(index),
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .all(Dimensions
                                                            .paddingSizeExtraSmall),
                                                    child: Icon(Icons.close,
                                                        size: 15,
                                                        color: Theme.of(context)
                                                            .cardColor),
                                                  ),
                                                ),
                                              ]),
                                            );
                                          },
                                        ),
                                      ),
                                    ]),
                                    const SizedBox(
                                        height: Dimensions.paddingSizeLarge),
                                    InkWell(
                                      onTap: () {
                                        Get.dialog(
                                            const CustomTimePickerWidget());
                                      },
                                      child: Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          borderRadius: BorderRadius.circular(
                                              Dimensions.radiusDefault),
                                          border: Border.all(
                                              color: Theme.of(context)
                                                  .disabledColor
                                                  .withValues(alpha: 0.5),
                                              width: 1),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal:
                                                Dimensions.paddingSizeLarge),
                                        child: Row(children: [
                                          Expanded(
                                              child: Text(
                                            '${authController.storeMinTime} : ${authController.storeMaxTime} ${authController.storeTimeUnit}',
                                            style: robotoMedium,
                                          )),
                                          Icon(Icons.access_time_filled,
                                              color: Theme.of(context)
                                                  .primaryColor),
                                        ]),
                                      ),
                                    ),
                                  ]),
                                ),
                                Visibility(
                                  visible: authController.storeStatus == 0.6,
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Expanded(
                                              child: CustomTextFieldWidget(
                                            hintText: 'first_name'.tr,
                                            labelText: 'first_name'.tr,
                                            controller: _fNameController,
                                            focusNode: _fNameFocus,
                                            nextFocus: _lNameFocus,
                                            inputType: TextInputType.name,
                                            capitalization:
                                                TextCapitalization.words,
                                          )),
                                          const SizedBox(
                                              width:
                                                  Dimensions.paddingSizeSmall),
                                          Expanded(
                                              child: CustomTextFieldWidget(
                                            hintText: 'last_name'.tr,
                                            labelText: 'last_name'.tr,
                                            controller: _lNameController,
                                            focusNode: _lNameFocus,
                                            nextFocus: _phoneFocus,
                                            inputType: TextInputType.name,
                                            capitalization:
                                                TextCapitalization.words,
                                          )),
                                        ]),
                                        const SizedBox(
                                            height: Dimensions
                                                .paddingSizeExtraLarge),
                                        CustomTextFieldWidget(
                                          hintText: 'enter_phone_number'.tr,
                                          labelText: 'phone_number'.tr,
                                          controller: _phoneController,
                                          focusNode: _phoneFocus,
                                          nextFocus: _emailFocus,
                                          inputType: TextInputType.phone,
                                          isPhone: true,
                                          showTitle: ResponsiveHelper.isDesktop(
                                              context),
                                          onCountryChanged:
                                              (CountryCode countryCode) {
                                            _countryDialCode =
                                                countryCode.dialCode;
                                          },
                                          countryDialCode: _countryDialCode !=
                                                  null
                                              ? CountryCode.fromCountryCode(
                                                      Get.find<
                                                              SplashController>()
                                                          .configModel!
                                                          .country!)
                                                  .code
                                              : Get.find<
                                                      LocalizationController>()
                                                  .locale
                                                  .countryCode,
                                        ),
                                        const SizedBox(
                                            height: Dimensions
                                                .paddingSizeExtraLarge),
                                        CustomTextFieldWidget(
                                          hintText: 'email'.tr,
                                          labelText: 'email'.tr,
                                          controller: _emailController,
                                          focusNode: _emailFocus,
                                          nextFocus: _passwordFocus,
                                          inputType: TextInputType.emailAddress,
                                        ),
                                        const SizedBox(
                                            height: Dimensions
                                                .paddingSizeExtraLarge),
                                        CustomTextFieldWidget(
                                          hintText: 'password'.tr,
                                          labelText: 'password'.tr,
                                          controller: _passwordController,
                                          focusNode: _passwordFocus,
                                          nextFocus: _confirmPasswordFocus,
                                          inputType:
                                              TextInputType.visiblePassword,
                                          isPassword: true,
                                          onChanged: (value) {
                                            if (value != null &&
                                                value.isNotEmpty) {
                                              if (!authController
                                                  .showPassView) {
                                                authController.showHidePass();
                                              }
                                              authController
                                                  .validPassCheck(value);
                                            } else {
                                              if (authController.showPassView) {
                                                authController.showHidePass();
                                              }
                                            }
                                          },
                                        ),
                                        authController.showPassView
                                            ? const PassViewWidget()
                                            : const SizedBox(),
                                        const SizedBox(
                                            height: Dimensions
                                                .paddingSizeExtraLarge),
                                        CustomTextFieldWidget(
                                          hintText: 'confirm_password'.tr,
                                          labelText: 'confirm_password'.tr,
                                          controller:
                                              _confirmPasswordController,
                                          focusNode: _confirmPasswordFocus,
                                          inputType:
                                              TextInputType.visiblePassword,
                                          isPassword: true,
                                          // nextFocus: authController.focusList[0],
                                        ),
                                        const SizedBox(
                                            height: Dimensions
                                                .paddingSizeExtraLarge),
                                        AdditionalDataSectionWidget(
                                            authController: authController,
                                            scrollController:
                                                _scrollController),
                                      ]),
                                ),
                                Visibility(
                                  visible: authController.storeStatus == 0.9,
                                  child: (Get.find<SplashController>()
                                                  .configModel!
                                                  .commissionBusinessModel ==
                                              0) &&
                                          (authController.packageModel !=
                                                  null &&
                                              authController.packageModel!
                                                  .packages!.isEmpty)
                                      ? Padding(
                                          padding: EdgeInsets.only(
                                              top: context.height * 0.3),
                                          child: Text(
                                              'no_subscription_package_is_available'
                                                  .tr,
                                              style: robotoMedium),
                                        )
                                      : Column(children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top:
                                                    Dimensions.paddingSizeLarge,
                                                bottom: Dimensions
                                                    .paddingSizeOverLarge),
                                            child: Center(
                                                child: Text(
                                                    'choose_your_business_plan'
                                                        .tr,
                                                    style: robotoBold)),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: Dimensions
                                                    .paddingSizeLarge),
                                            child: Row(children: [
                                              Get.find<SplashController>()
                                                          .configModel!
                                                          .commissionBusinessModel !=
                                                      0
                                                  ? Expanded(
                                                      child: BaseCardWidget(
                                                        authController:
                                                            authController,
                                                        title: 'commission_base'
                                                            .tr,
                                                        index: 0,
                                                        onTap: () =>
                                                            authController
                                                                .setBusiness(0),
                                                      ),
                                                    )
                                                  : const SizedBox(),
                                              const SizedBox(
                                                  width: Dimensions
                                                      .paddingSizeDefault),
                                              (Get.find<SplashController>()
                                                              .configModel!
                                                              .subscriptionBusinessModel !=
                                                          0) &&
                                                      (authController
                                                                  .packageModel !=
                                                              null &&
                                                          authController
                                                              .packageModel!
                                                              .packages!
                                                              .isNotEmpty)
                                                  ? Expanded(
                                                      child: BaseCardWidget(
                                                        authController:
                                                            authController,
                                                        title:
                                                            'subscription_base'
                                                                .tr,
                                                        index: 1,
                                                        onTap: () =>
                                                            authController
                                                                .setBusiness(1),
                                                      ),
                                                    )
                                                  : const SizedBox(),
                                            ]),
                                          ),
                                          const SizedBox(
                                              height: Dimensions
                                                  .paddingSizeExtraLarge),
                                          authController.businessIndex == 0
                                              ? Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: Dimensions
                                                          .paddingSizeLarge),
                                                  child: Text(
                                                    "${'restaurant_will_pay'.tr} ${Get.find<SplashController>().configModel!.adminCommission}% ${'commission_to'.tr} ${Get.find<SplashController>().configModel!.businessName} ${'from_each_order_You_will_get_access_of_all'.tr}",
                                                    style:
                                                        robotoRegular.copyWith(
                                                            fontSize: Dimensions
                                                                .fontSizeSmall,
                                                            color: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyLarge
                                                                ?.color
                                                                ?.withValues(
                                                                    alpha:
                                                                        0.7)),
                                                    textAlign:
                                                        TextAlign.justify,
                                                    textScaler:
                                                        const TextScaler.linear(
                                                            1.1),
                                                  ),
                                                )
                                              : (authController.packageModel !=
                                                          null &&
                                                      authController
                                                          .packageModel!
                                                          .packages!
                                                          .isNotEmpty)
                                                  ? Column(children: [
                                                      Padding(
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: Dimensions
                                                                .paddingSizeLarge),
                                                        child: Text(
                                                          'run_restaurant_by_purchasing_subscription_packages'
                                                              .tr,
                                                          style: robotoRegular.copyWith(
                                                              fontSize: Dimensions
                                                                  .fontSizeSmall,
                                                              color: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodyLarge
                                                                  ?.color
                                                                  ?.withValues(
                                                                      alpha:
                                                                          0.7)),
                                                          textAlign:
                                                              TextAlign.justify,
                                                          textScaler:
                                                              const TextScaler
                                                                  .linear(1.1),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: Dimensions
                                                              .paddingSizeLarge),
                                                      SizedBox(
                                                        height: 440,
                                                        child: authController
                                                                    .packageModel !=
                                                                null
                                                            ? authController
                                                                    .packageModel!
                                                                    .packages!
                                                                    .isNotEmpty
                                                                ? Swiper(
                                                                    itemCount: authController
                                                                        .packageModel!
                                                                        .packages!
                                                                        .length,
                                                                    viewportFraction:
                                                                        authController.packageModel!.packages!.length >
                                                                                1
                                                                            ? 0.7
                                                                            : 1,
                                                                    physics: authController.packageModel!.packages!.length >
                                                                            1
                                                                        ? const AlwaysScrollableScrollPhysics()
                                                                        : const NeverScrollableScrollPhysics(),
                                                                    itemBuilder:
                                                                        (context,
                                                                            index) {
                                                                      Packages
                                                                          package =
                                                                          authController
                                                                              .packageModel!
                                                                              .packages![index];

                                                                      return PackageCardWidget(
                                                                        currentIndex: authController.activeSubscriptionIndex ==
                                                                                index
                                                                            ? index
                                                                            : null,
                                                                        package:
                                                                            package,
                                                                      );
                                                                    },
                                                                    onIndexChanged:
                                                                        (index) {
                                                                      authController
                                                                          .selectSubscriptionCard(
                                                                              index);
                                                                    },
                                                                  )
                                                                : Center(
                                                                    child: Column(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        children: [
                                                                          Text(
                                                                              'no_package_available'.tr,
                                                                              style: robotoMedium),
                                                                        ]),
                                                                  )
                                                            : const Center(
                                                                child:
                                                                    CircularProgressIndicator()),
                                                      ),
                                                    ])
                                                  : const SizedBox(),
                                        ]),
                                ),
                              ]),
                            ),
                          ),
                        ),
                        ((authController.storeStatus == 0.9) &&
                                (Get.find<SplashController>()
                                        .configModel!
                                        .commissionBusinessModel ==
                                    0) &&
                                (authController.packageModel != null &&
                                    authController
                                        .packageModel!.packages!.isEmpty))
                            ? const SizedBox()
                            : !authController.isLoading
                                ? CustomButtonWidget(
                                    margin: const EdgeInsets.all(
                                        Dimensions.paddingSizeSmall),
                                    buttonText: authController.storeStatus ==
                                                0.1 ||
                                            authController.storeStatus == 0.6
                                        ? 'next'.tr
                                        : 'submit'.tr,
                                    onPressed: () {
                                      bool defaultNameNull = false;
                                      bool defaultAddressNull = false;
                                      bool customFieldEmpty = false;

                                      for (int index = 0;
                                          index < _languageList.length;
                                          index++) {
                                        if (_languageList[index].key == 'en') {
                                          if (_nameController[index]
                                              .text
                                              .trim()
                                              .isEmpty) {
                                            defaultNameNull = true;
                                          }
                                          if (_addressController[index]
                                              .text
                                              .trim()
                                              .isEmpty) {
                                            defaultAddressNull = true;
                                          }
                                          break;
                                        }
                                      }

                                      Map<String, dynamic> additionalData = {};
                                      List<FilePickerResult>
                                          additionalDocuments = [];
                                      List<String>
                                          additionalDocumentsInputType = [];

                                      if (authController.storeStatus == 0.6) {
                                        for (Data data
                                            in authController.dataList!) {
                                          bool isTextField =
                                              data.fieldType == 'text' ||
                                                  data.fieldType == 'number' ||
                                                  data.fieldType == 'email' ||
                                                  data.fieldType == 'phone';
                                          bool isDate =
                                              data.fieldType == 'date';
                                          bool isCheckBox =
                                              data.fieldType == 'check_box';
                                          bool isFile =
                                              data.fieldType == 'file';
                                          int index = authController.dataList!
                                              .indexOf(data);
                                          bool isRequired =
                                              data.isRequired == 1;

                                          if (isTextField) {
                                            if (authController
                                                    .additionalList![index]
                                                    .text !=
                                                '') {
                                              additionalData.addAll({
                                                data.inputData!: authController
                                                    .additionalList![index].text
                                              });
                                            } else {
                                              if (isRequired) {
                                                customFieldEmpty = true;
                                                showCustomSnackBar(
                                                    '${data.placeholderData} ${'can_not_be_empty'.tr}');
                                                break;
                                              }
                                            }
                                          } else if (isDate) {
                                            if (authController
                                                    .additionalList![index] !=
                                                null) {
                                              additionalData.addAll({
                                                data.inputData!: authController
                                                    .additionalList![index]
                                              });
                                            } else {
                                              if (isRequired) {
                                                customFieldEmpty = true;
                                                showCustomSnackBar(
                                                    '${data.placeholderData} ${'can_not_be_empty'.tr}');
                                                break;
                                              }
                                            }
                                          } else if (isCheckBox) {
                                            List<String> checkData = [];
                                            bool noNeedToGoElse = false;
                                            for (var e in authController
                                                .additionalList![index]) {
                                              if (e != 0) {
                                                checkData.add(e);
                                                customFieldEmpty = false;
                                                noNeedToGoElse = true;
                                              } else if (!noNeedToGoElse) {
                                                customFieldEmpty = true;
                                              }
                                            }
                                            if (customFieldEmpty &&
                                                isRequired) {
                                              showCustomSnackBar(
                                                  '${'please_set_data_in'.tr} ${authController.dataList![index].inputData!.replaceAll('_', ' ')} ${'field'.tr}');
                                              break;
                                            } else {
                                              additionalData.addAll(
                                                  {data.inputData!: checkData});
                                            }
                                          } else if (isFile) {
                                            if (authController
                                                        .additionalList![index]
                                                        .length ==
                                                    0 &&
                                                isRequired) {
                                              customFieldEmpty = true;
                                              showCustomSnackBar(
                                                  '${'please_add'.tr} ${authController.dataList![index].inputData!.replaceAll('_', ' ')}');
                                              break;
                                            } else {
                                              authController
                                                  .additionalList![index]
                                                  .forEach((file) {
                                                additionalDocuments.add(file);
                                                additionalDocumentsInputType
                                                    .add(authController
                                                        .dataList![index]
                                                        .inputData!);
                                              });
                                            }
                                          }
                                        }
                                      }

                                      String vat = _vatController.text.trim();
                                      String minTime =
                                          authController.storeMinTime;
                                      String maxTime =
                                          authController.storeMaxTime;
                                      String fName =
                                          _fNameController.text.trim();
                                      String lName =
                                          _lNameController.text.trim();
                                      String phone =
                                          _phoneController.text.trim();
                                      String email =
                                          _emailController.text.trim();
                                      String password =
                                          _passwordController.text.trim();
                                      String confirmPassword =
                                          _confirmPasswordController.text
                                              .trim();
                                      String phoneWithCountryCode =
                                          _countryDialCode != null
                                              ? _countryDialCode! + phone
                                              : phone;

                                      bool valid = false;
                                      try {
                                        double.parse(maxTime);
                                        double.parse(minTime);
                                        valid = true;
                                      } on FormatException {
                                        valid = false;
                                      }

                                      if (authController.storeStatus == 0.1 ||
                                          authController.storeStatus == 0.6) {
                                        if (authController.storeStatus == 0.1) {
                                          if (authController.pickedLogo ==
                                              null) {
                                            showCustomSnackBar(
                                                'select_restaurant_logo'.tr);
                                          } else if (authController
                                                  .pickedCover ==
                                              null) {
                                            showCustomSnackBar(
                                                'select_restaurant_cover_photo'
                                                    .tr);
                                          } else if (defaultNameNull) {
                                            showCustomSnackBar(
                                                'enter_restaurant_name'.tr);
                                          } else if (defaultAddressNull) {
                                            showCustomSnackBar(
                                                'enter_restaurant_address'.tr);
                                          } else if (vat.isEmpty) {
                                            showCustomSnackBar(
                                                'enter_vat_amount'.tr);
                                          } else if (minTime.isEmpty) {
                                            showCustomSnackBar(
                                                'enter_minimum_delivery_time'
                                                    .tr);
                                          } else if (maxTime.isEmpty) {
                                            showCustomSnackBar(
                                                'enter_maximum_delivery_time'
                                                    .tr);
                                          } else if (!valid) {
                                            showCustomSnackBar(
                                                'please_enter_the_max_min_delivery_time'
                                                    .tr);
                                          } else if (valid &&
                                              double.parse(minTime) >
                                                  double.parse(maxTime)) {
                                            showCustomSnackBar(
                                                'maximum_delivery_time_can_not_be_smaller_then_minimum_delivery_time'
                                                    .tr);
                                          } else if (locationController
                                                  .restaurantLocation ==
                                              null) {
                                            showCustomSnackBar(
                                                'set_restaurant_location'.tr);
                                          } else {
                                            _scrollController.jumpTo(
                                                _scrollController
                                                    .position.minScrollExtent);
                                            authController
                                                .storeStatusChange(0.6);
                                            firstTime = true;
                                          }
                                        } else if (authController.storeStatus ==
                                            0.6) {
                                          if (fName.isEmpty) {
                                            showCustomSnackBar(
                                                'enter_your_first_name'.tr);
                                          } else if (lName.isEmpty) {
                                            showCustomSnackBar(
                                                'enter_your_last_name'.tr);
                                          } else if (phone.isEmpty) {
                                            showCustomSnackBar(
                                                'enter_your_phone_number'.tr);
                                          } else if (email.isEmpty) {
                                            showCustomSnackBar(
                                                'enter_your_email_address'.tr);
                                          } else if (!GetUtils.isEmail(email)) {
                                            showCustomSnackBar(
                                                'enter_a_valid_email_address'
                                                    .tr);
                                          } else if (password.isEmpty) {
                                            showCustomSnackBar(
                                                'enter_password'.tr);
                                          } else if (password.length < 6) {
                                            showCustomSnackBar(
                                                'password_should_be'.tr);
                                          } else if (password !=
                                              confirmPassword) {
                                            showCustomSnackBar(
                                                'confirm_password_does_not_matched'
                                                    .tr);
                                          } else if (customFieldEmpty) {
                                            if (kDebugMode) {
                                              print(
                                                  'not provide addition data');
                                            }
                                          } else {
                                            _scrollController.jumpTo(
                                                _scrollController
                                                    .position.minScrollExtent);
                                            authController
                                                .storeStatusChange(0.9);
                                          }
                                        } else {
                                          authController.storeStatusChange(0.9);
                                        }
                                      } else {
                                        List<Translation> translation = [];
                                        for (int index = 0;
                                            index < _languageList.length;
                                            index++) {
                                          translation.add(Translation(
                                            locale: _languageList[index].key,
                                            key: 'name',
                                            value: _nameController[index]
                                                    .text
                                                    .trim()
                                                    .isNotEmpty
                                                ? _nameController[index]
                                                    .text
                                                    .trim()
                                                : _nameController[0]
                                                    .text
                                                    .trim(),
                                          ));
                                          translation.add(Translation(
                                            locale: _languageList[index].key,
                                            key: 'address',
                                            value: _addressController[index]
                                                    .text
                                                    .trim()
                                                    .isNotEmpty
                                                ? _addressController[index]
                                                    .text
                                                    .trim()
                                                : _addressController[0]
                                                    .text
                                                    .trim(),
                                          ));
                                        }

                                        List<String> cuisines = [];
                                        for (var index in restaurantController
                                            .selectedCuisines!) {
                                          cuisines.add(restaurantController
                                              .cuisineModel!.cuisines![index].id
                                              .toString());
                                        }

                                        Map<String, String> data = {};

                                        data.addAll(RestaurantBodyModel(
                                          deliveryTimeType:
                                              authController.storeTimeUnit,
                                          translation: jsonEncode(translation),
                                          vat: vat,
                                          minDeliveryTime: minTime,
                                          maxDeliveryTime: maxTime,
                                          lat: locationController
                                              .restaurantLocation!.latitude
                                              .toString(),
                                          email: email,
                                          lng: locationController
                                              .restaurantLocation!.longitude
                                              .toString(),
                                          fName: fName,
                                          lName: lName,
                                          phone: phoneWithCountryCode,
                                          password: password,
                                          zoneId: locationController
                                              .zoneList![locationController
                                                  .selectedZoneIndex!]
                                              .id
                                              .toString(),
                                          cuisineId: cuisines,
                                          businessPlan:
                                              authController.businessIndex == 0
                                                  ? 'commission'
                                                  : 'subscription',
                                          packageId: authController
                                                          .packageModel!
                                                          .packages !=
                                                      null &&
                                                  authController.packageModel!
                                                      .packages!.isNotEmpty
                                              ? authController
                                                  .packageModel!
                                                  .packages![authController
                                                      .activeSubscriptionIndex]
                                                  .id!
                                                  .toString()
                                              : '',
                                        ).toJson());

                                        data.addAll({
                                          'additional_data':
                                              jsonEncode(additionalData),
                                        });

                                        authController.registerRestaurant(
                                            data,
                                            additionalDocuments,
                                            additionalDocumentsInputType);
                                      }
                                    },
                                  )
                                : const Center(
                                    child: Padding(
                                    padding: EdgeInsets.all(
                                        Dimensions.paddingSizeDefault),
                                    child: CircularProgressIndicator(),
                                  )),
                      ]),
                )),
              ),
            ),
          );
        });
      });
    });
  }

  Future<void> _showBackPressedDialogue(String title) async {
    Get.dialog(
        ConfirmationDialogWidget(
          icon: Images.support,
          title: title,
          description: 'are_you_sure_to_go_back'.tr,
          isLogOut: true,
          onYesPressed: () => Get.offAllNamed(RouteHelper.getSignInRoute()),
        ),
        useSafeArea: false);
  }
}
