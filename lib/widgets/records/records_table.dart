import 'package:flutter/material.dart';

class RecordsTable extends StatelessWidget {
  final List<Map<String, dynamic>> filteredWeights;
  final bool isSortedByWeight;
  final bool isAscending;
  final Color? arrowColor;
  final Function(bool) toggleSorting;
  final double Function(double) convertWeight;
  final bool isKg;

  const RecordsTable({
    required this.filteredWeights,
    required this.isSortedByWeight,
    required this.isAscending,
    required this.arrowColor,
    required this.toggleSorting,
    required this.convertWeight,
    required this.isKg,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
            ),
            child: DataTable(
              columnSpacing: 64.0,
              dataRowHeight: 65.0,
              columns: [
                DataColumn(
                  label: Expanded(
                    child: GestureDetector(
                      onTap: () => toggleSorting(false),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Text('Exercise',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          if (!isSortedByWeight)
                            Row(
                              children: [
                                const SizedBox(width: 4.0),
                                Icon(
                                  isAscending
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 16.0,
                                  color: arrowColor,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: GestureDetector(
                      onTap: () => toggleSorting(true),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Weight [${isKg ? 'kg' : 'lbs'}]',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          if (isSortedByWeight)
                            Row(
                              children: [
                                const SizedBox(width: 4.0),
                                Icon(
                                  isAscending
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 16.0,
                                  color: arrowColor,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              rows: filteredWeights.map((record) {
                final exercise = record['exercise'] as String;
                final weight = record['weight'];
                final reps = record['reps'];
                final displayWeight = convertWeight(
                    weight is String ? double.parse(weight) : weight);

                return DataRow(cells: [
                  DataCell(Text(exercise)),
                  DataCell(
                    Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Text(
                        '${displayWeight.toStringAsFixed(1)} x $reps reps',
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ]);
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
