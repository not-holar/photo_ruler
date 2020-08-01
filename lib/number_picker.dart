import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumberPicker extends StatelessWidget {
  static const _padding = EdgeInsets.fromLTRB(15, 5, 10, 5);
  static const _iconSize = 16;

  final Color color;
  final double initialNumber;
  final String Function(double n) numberFormatter;
  final void Function(double n) onChange;

  final double width;
  final double height;

  const NumberPicker({
    Key key,
    this.color,
    this.initialNumber = 1,
    this.numberFormatter,
    @required this.onChange,
    this.width = 100,
    this.height,
  })  : assert(onChange != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = numberFormatter ?? (n) => n.toStringAsFixed(2);

    double _value = initialNumber;

    return SizedBox(
      width: width,
      height: height ?? _iconSize * 2 + _padding.vertical,
      child: Material(
        color: color ?? theme.inputDecorationTheme.fillColor,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: _padding,
          child: StatefulBuilder(builder: (context, setState) {
            bool _textFieldEditable = false;

            return Row(children: [
              Expanded(
                child: StatefulBuilder(builder: (context, setTextState) {
                  if (_textFieldEditable) {
                    return Focus(
                      onFocusChange: (focused) {
                        if (!focused) {
                          setState(() => null);
                          onChange(_value);
                        }
                      },
                      child: TextField(
                        controller: TextEditingController(text: fmt(_value)),
                        style: theme.textTheme.bodyText1,
                        decoration:
                            const InputDecoration.collapsed(hintText: ""),
                        autofocus: true,
                        autocorrect: false,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp("[0-9.\\-]"),
                          )
                        ],
                        onChanged: (str) {
                          final x = double.tryParse(str);
                          if (x != null) {
                            _value = x;
                          }
                        },
                      ),
                    );
                  } else {
                    return GestureDetector(
                      onTap: () => setTextState(
                        () => _textFieldEditable = true,
                      ),
                      child: Text(
                        fmt(_value),
                      ),
                    );
                  }
                }),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    splashRadius: 20,
                    constraints: BoxConstraints.tight(const Size.square(16)),
                    icon: const Icon(Icons.keyboard_arrow_up),
                    onPressed: () => setState(() {
                      _value += 1;
                      onChange(_value);
                    }),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    splashRadius: 20,
                    constraints: BoxConstraints.tight(const Size.square(16)),
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onPressed: () => setState(() {
                      _value -= 1;
                      onChange(_value);
                    }),
                  ),
                ],
              ),
            ]);
          }),
        ),
      ),
    );
  }
}
