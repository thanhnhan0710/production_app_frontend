import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:production_app_frontend/features/quality/iqc/domain/iqc_result_model.dart';
import 'package:production_app_frontend/features/quality/iqc/presentation/bloc/iqc_result_cubit.dart';


class IQCFormDialog extends StatefulWidget {
  final int batchId;

  const IQCFormDialog({super.key, required this.batchId});

  @override
  State<IQCFormDialog> createState() => _IQCFormDialogState();
}

class _IQCFormDialogState extends State<IQCFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  final _testerNameCtrl = TextEditingController();
  final _tensileCtrl = TextEditingController();
  final _elongationCtrl = TextEditingController();
  final _colorFastnessCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  
  IQCResultStatus _finalResult = IQCResultStatus.pass; // Mặc định Pass

  @override
  Widget build(BuildContext context) {
    // Cần bọc BlocProvider nếu dialog được gọi từ nơi chưa có Cubit, 
    // nhưng ở đây ta sẽ dùng instance từ màn hình cha truyền vào hoặc tạo mới repository để gọi API.
    // Để đơn giản, ta dùng BlocProvider.value từ màn hình cha (BatchDetail) truyền xuống.
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("New Quality Test", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003366))),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _testerNameCtrl,
                  decoration: _inputDeco("Tester Name"),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(child: TextFormField(controller: _tensileCtrl, decoration: _inputDeco("Tensile Strength"), keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: _elongationCtrl, decoration: _inputDeco("Elongation (%)"), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(controller: _colorFastnessCtrl, decoration: _inputDeco("Color Fastness (1-5)"), keyboardType: TextInputType.number),
                
                const SizedBox(height: 24),
                const Text("Final Conclusion", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                // Radio Buttons cho Pass/Fail
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<IQCResultStatus>(
                        title: const Text("Pass", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        value: IQCResultStatus.pass,
                        groupValue: _finalResult,
                        activeColor: Colors.green,
                        onChanged: (val) => setState(() => _finalResult = val!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<IQCResultStatus>(
                        title: const Text("Fail", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        value: IQCResultStatus.fail,
                        groupValue: _finalResult,
                        activeColor: Colors.red,
                        onChanged: (val) => setState(() => _finalResult = val!),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                TextFormField(controller: _noteCtrl, decoration: _inputDeco("Note"), maxLines: 2),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _submitForm,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366), foregroundColor: Colors.white),
          child: const Text("Save Result"),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final result = IQCResult(
        batchId: widget.batchId,
        testerName: _testerNameCtrl.text,
        tensileStrength: double.tryParse(_tensileCtrl.text),
        elongation: double.tryParse(_elongationCtrl.text),
        colorFastness: double.tryParse(_colorFastnessCtrl.text),
        finalResult: _finalResult,
        note: _noteCtrl.text,
      );

      // Gọi Cubit từ context cha (BatchDetailScreen)
      context.read<IQCResultCubit>().saveResult(result: result, isEdit: false);
      Navigator.pop(context, true); // Trả về true để báo reload
    }
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}