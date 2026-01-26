import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';

// Domain
import '../../domain/bom_model.dart';
import '../../../material/domain/material_model.dart';

// Cubit - Sử dụng alias mat_bloc
import '../../../material/presentation/bloc/material_cubit.dart' as mat_bloc;

class MaterialDetailDialog extends StatefulWidget {
  final BOMDetail? detail;
  final int bomId; // [FIX 1] Thêm tham số bomId bắt buộc

  const MaterialDetailDialog({
    super.key, 
    this.detail, 
    required this.bomId
  });

  @override
  State<MaterialDetailDialog> createState() => _MaterialDetailDialogState();
}

class _MaterialDetailDialogState extends State<MaterialDetailDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _threadsCtrl = TextEditingController();
  final _yarnTypeCtrl = TextEditingController();
  final _twistCtrl = TextEditingController();
  final _crossweaveCtrl = TextEditingController();
  final _actualLenCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  BOMComponentType _selectedType = BOMComponentType.ground;
  int? _selectedMaterialId;

  @override
  void initState() {
    super.initState();
    context.read<mat_bloc.MaterialCubit>().loadMaterials();

    if (widget.detail != null) {
      final d = widget.detail!;
      _selectedType = d.componentType;
      _selectedMaterialId = d.materialId;
      _threadsCtrl.text = d.threads.toString();
      _yarnTypeCtrl.text = d.yarnTypeName;
      _twistCtrl.text = d.twisted.toString();
      _crossweaveCtrl.text = d.crossweaveRate.toString();
      _actualLenCtrl.text = d.actualLengthCm.toString();
      _noteCtrl.text = d.note;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.detail == null ? "Add Component" : "Edit Component"),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Component Type
                DropdownButtonFormField<BOMComponentType>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: "Type", border: OutlineInputBorder()),
                  items: BOMComponentType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))).toList(),
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
                const SizedBox(height: 12),

                // 2. Material Select
                BlocBuilder<mat_bloc.MaterialCubit, mat_bloc.MaterialState>(
                  builder: (context, state) {
                    List<MaterialModel> materials = [];
                    if (state is mat_bloc.MaterialLoaded) {
                      materials = state.materials;
                    }
                    
                    return DropdownButtonFormField<int>(
                      value: _selectedMaterialId,
                      decoration: const InputDecoration(labelText: "Material", border: OutlineInputBorder()),
                      items: materials.map((m) => DropdownMenuItem(
                        value: m.id,
                        child: Text("${m.materialCode} - ${m.materialType ?? ''}", overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedMaterialId = val;
                          // Auto-fill tên sợi
                          final mat = materials.firstWhere((element) => element.id == val);
                          if (_yarnTypeCtrl.text.isEmpty) {
                            _yarnTypeCtrl.text = "${mat.materialCode} ${mat.specDenier ?? ''}";
                          }
                        });
                      },
                      validator: (v) => v == null ? "Required" : null,
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 3. Yarn Name
                TextFormField(
                  controller: _yarnTypeCtrl,
                  decoration: const InputDecoration(labelText: "Yarn Name / Code", border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 12),

                // 4. Tech Specs
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _threadsCtrl,
                        decoration: const InputDecoration(labelText: "Threads (Ends)", border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _twistCtrl,
                        decoration: const InputDecoration(labelText: "Twist", border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _actualLenCtrl,
                        decoration: const InputDecoration(labelText: "Actual Len (cm)", border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _crossweaveCtrl,
                        decoration: const InputDecoration(labelText: "Crossweave (0-1)", border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(labelText: "Note", border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newDetail = BOMDetail(
                detailId: widget.detail?.detailId ?? 0,
                // [FIX 2] Sử dụng widget.bomId được truyền vào thay vì lấy từ detail (vì detail null khi tạo mới)
                bomId: widget.bomId, 
                materialId: _selectedMaterialId ?? 1,
                componentType: _selectedType,
                threads: int.tryParse(_threadsCtrl.text) ?? 0,
                yarnTypeName: _yarnTypeCtrl.text,
                twisted: double.tryParse(_twistCtrl.text) ?? 1.0,
                crossweaveRate: double.tryParse(_crossweaveCtrl.text) ?? 0.0,
                actualLengthCm: double.tryParse(_actualLenCtrl.text) ?? 0.0,
                note: _noteCtrl.text,
                // Các trường computed để 0
                yarnDtex: 0, weightPerYarnGm: 0, actualWeightCal: 0, weightPercentage: 0, bomGm: 0,
              );
              Navigator.pop(context, newDetail);
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}