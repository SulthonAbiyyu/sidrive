// ============================================================================
// CHAT INPUT WIDGET
// Input field dengan validasi untuk chat
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sidrive/services/chat_validation_service.dart';
import 'package:sidrive/models/chat_models.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSend;
  final bool enabled;
  final ChatContext context;

  const ChatInput({
    super.key,
    required this.onSend,
    this.enabled = true,
    required this.context,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _validationService = ChatValidationService();
  
  bool _hasText = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _textController.text;
    final hasText = text.trim().isNotEmpty;
    
    // Reset validation error when text changes
    if (_validationError != null) {
      setState(() => _validationError = null);
    }
    
    if (_hasText != hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    
    // Validate jika customer-umkm
    if (widget.context == ChatContext.customerUmkm) {
      final isValid = _validationService.validateMessage(text);
      if (!isValid) {
        setState(() {
          _validationError = _validationService.getValidationErrorMessage();
        });
        _showValidationDialog();
        return;
      }
    }
    
    // Send message
    widget.onSend(text);
    _textController.clear();
    _focusNode.requestFocus();
  }

  void _showValidationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 28.sp,
            ),
            SizedBox(width: 12.w),
            const Text('Pesan Tidak Valid'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _validationError ?? '',
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18.sp,
                    color: Colors.orange.shade800,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _validationService.getSuggestionMessage(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Text input
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: _validationError != null 
                        ? Colors.red.shade300 
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Emoji button (optional)
                    // GestureDetector(
                    //   onTap: () {
                    //     // Show emoji picker
                    //   },
                    //   child: Icon(
                    //     Icons.emoji_emotions_outlined,
                    //     color: Colors.grey.shade600,
                    //     size: 24.sp,
                    //   ),
                    // ),
                    // SizedBox(width: 8.w),
                    
                    // Text field
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        enabled: widget.enabled,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: widget.enabled 
                              ? 'Tulis pesan...' 
                              : 'Chat belum aktif',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14.sp,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black87,
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                    
                    // Attachment button (optional, untuk future)
                    // GestureDetector(
                    //   onTap: widget.enabled ? _handleAttachment : null,
                    //   child: Icon(
                    //     Icons.attach_file,
                    //     color: widget.enabled 
                    //         ? Colors.grey.shade600 
                    //         : Colors.grey.shade400,
                    //     size: 24.sp,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
            
            SizedBox(width: 8.w),
            
            // Send button
            GestureDetector(
              onTap: _hasText && widget.enabled ? _handleSend : null,
              child: Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  gradient: _hasText && widget.enabled
                      ? const LinearGradient(
                          colors: [
                            Color(0xFFFF85A1),
                            Color(0xFFFF6B9D),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: !_hasText || !widget.enabled 
                      ? Colors.grey.shade300 
                      : null,
                  shape: BoxShape.circle,
                  boxShadow: _hasText && widget.enabled
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF85A1).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}