import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/simulator_viewmodel.dart';

class SimulatorScreen extends StatelessWidget {
  const SimulatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Dashboard Simulator'),
        centerTitle: true,
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
      ),
      body: Consumer<SimulatorViewModel>(
        builder: (context, viewModel, child) {
          return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Control Panel
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Auto Mode',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Switch(
                                      value: viewModel.isAutoMode,
                                      onChanged: (_) =>
                                          viewModel.toggleAutoMode(),
                                      activeThumbColor: Colors.purple[700],
                                      inactiveThumbColor: Colors.purple[100],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: viewModel.startSimulation,
                                        icon: const Icon(Icons.play_arrow),
                                        label: const Text('Start'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: viewModel.stopSimulation,
                                        icon: const Icon(Icons.stop),
                                        label: const Text('Stop'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Sensor Controls
                        const Text(
                          'Sensor Values',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSensorSlider(
                          context,
                          'Temperature (°C)',
                          viewModel.temperature,
                          20,
                          40,
                          viewModel.setTemperature,
                          enabled: !viewModel.isAutoMode,
                        ),
                        _buildSensorSlider(
                          context,
                          'pH Level',
                          viewModel.pH,
                          5,
                          8,
                          viewModel.setPH,
                          enabled: !viewModel.isAutoMode,
                        ),
                        _buildSensorSlider(
                          context,
                          'Water Level (%)',
                          viewModel.waterLevel,
                          0,
                          100,
                          viewModel.setWaterLevel,
                          enabled: !viewModel.isAutoMode,
                        ),
                        _buildSensorSlider(
                          context,
                          'TDS (ppm)',
                          viewModel.tds,
                          0,
                          2000,
                          viewModel.setTDS,
                          enabled: !viewModel.isAutoMode,
                        ),
                        _buildSensorSlider(
                          context,
                          'Light Intensity (lux)',
                          viewModel.lightIntensity,
                          0,
                          1000,
                          viewModel.setLightIntensity,
                          enabled: !viewModel.isAutoMode,
                        ),
                        const SizedBox(height: 24),

                        // Actuator Controls
                        const Text(
                          'Actuator Status',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildActuatorSwitch(
                          'Water Pump',
                          viewModel.waterPump,
                          viewModel.toggleWaterPump,
                          Icons.water_drop,
                        ),
                        _buildActuatorSwitch(
                          'Nutrient Pump',
                          viewModel.nutrientPump,
                          viewModel.toggleNutrientPump,
                          Icons.science,
                        ),
                        _buildActuatorSwitch(
                          'Lights',
                          viewModel.lights,
                          viewModel.toggleLights,
                          Icons.lightbulb,
                        ),
                        _buildActuatorSwitch(
                          'Fan',
                          viewModel.fan,
                          viewModel.toggleFan,
                          Icons.air,
                        ),
                      ],
                    ),
                  );
        },
      ),
    );
  }

  Widget _buildSensorSlider(
    BuildContext context,
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged, {
    bool enabled = true,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: enabled
                    ? Colors.purple[700]
                    : Colors.purple[100],
                thumbColor: enabled ? Colors.purple[700] : Colors.purple[100],
                inactiveTrackColor: Colors.purple[100],
                disabledActiveTrackColor: Colors.purple[100],
                disabledThumbColor: Colors.purple[100],
                disabledInactiveTrackColor: Colors.purple[50],
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActuatorSwitch(
    String label,
    bool value,
    VoidCallback onToggle,
    IconData icon,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: value ? Colors.green : Colors.grey,
          size: 32,
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        trailing: Switch(
          value: value,
          onChanged: (_) => onToggle(),
          activeThumbColor: Colors.purple[700],
          inactiveThumbColor: Colors.purple[100],
        ),
      ),
    );
  }
}
