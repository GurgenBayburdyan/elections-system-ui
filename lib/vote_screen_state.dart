import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'Candidate.dart';
import 'ElectionLocation.dart';
import 'Elector.dart';


class VoteScreen extends StatefulWidget {
  const VoteScreen({super.key, required this.title});

  final String title;

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  String selectedElectorId = '';
  String selectedElectionLocationId = '';
  String selectedCandidateId = '';

  List<Elector> electors = [];
  List<ElectionLocation> electionLocations = [];
  List<Candidate> candidates = [];

  var statistics = {};

  String electorsUrl = "http://localhost:8080/electors";
  String electionLocationsUrl = "http://localhost:8080/electionLocation";
  String candidatesUrl = "http://localhost:8080/candidates";
  String statisticsUrl = "http://localhost:8080/statistics";
  String votesUrl = "http://localhost:8080/votes";

  TextEditingController passportController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController dateOfBirthController = TextEditingController();
  TextEditingController numberController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getAll();
    getStatistics();
  }

  dynamic addCandidate(String firstName, String lastName, String number) async {
    await http.post(
      Uri.parse(candidatesUrl),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: json.encode(
          {'firstName': firstName, 'lastName': lastName, 'number': number}),
    );
  }

  dynamic findElectorByPassportNumber(String passportNumber) async {
    final electorResponse =
        await http.get(Uri.parse('$electorsUrl/$passportNumber'));
    final electorData = jsonDecode(electorResponse.body);
    int electorId = electorData['id'];
    return electorId;
  }

  dynamic vote(String passportNumber, String electionLocationId,
      String candidateId) async {
    int electorId = await findElectorByPassportNumber(passportNumber);

    await http.post(
      Uri.parse(votesUrl),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'electorId': electorId,
        'electionLocationId': int.parse(electionLocationId),
        'candidateId': int.parse(candidateId)
      }),
    );
  }

  dynamic addElector(String firstName, String lastName, String passportNumber,
      String dateOfBirth) async {
    DateTime date = DateTime.parse(dateOfBirth);
    String dateTime = date.toIso8601String();

    await http.post(
      Uri.parse(electorsUrl),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'firstName': firstName,
        'lastName': lastName,
        'passportNumber': passportNumber,
        'dateOfBirth': dateTime,
      }),
    );
  }

  dynamic addElectionLocation(String address) async {
    await http.post(
      Uri.parse(electionLocationsUrl),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: json.encode({'address': address}),
    );
  }

  getAll() async {
    final electorsResponse = await http.get(Uri.parse(electorsUrl));
    final electionLocationsResponse =
        await http.get(Uri.parse(electionLocationsUrl));
    final candidatesResponse = await http.get(Uri.parse(candidatesUrl));

    setState(() {
      electors = List<Elector>.from(
        json
            .decode(electorsResponse.body)
            .map((data) => Elector.fromJson(data)),
      );
      electionLocations = List<ElectionLocation>.from(
        json
            .decode(electionLocationsResponse.body)
            .map((data) => ElectionLocation.fromJson(data)),
      );
      candidates = List<Candidate>.from(
        json
            .decode(candidatesResponse.body)
            .map((data) => Candidate.fromJson(data)),
      );
    });
  }

  getStatistics() async {
    final statisticsResponse = await http.get(Uri.parse(statisticsUrl));
    setState(() {
      var data = jsonDecode(statisticsResponse.body);

      Map<String, dynamic> statisticsData = data['statistics'];

      Map<int, Map<int, double>> statisticsMap = {};

      statisticsData.forEach((k1, k2) {
        Map<int, double> candidateStatistics = {};
        (k2 as Map<String, dynamic>).forEach((innerKey, value) {
          candidateStatistics[int.parse(innerKey)] = (value as num).toDouble();
        });
        statisticsMap[int.parse(k1)] = candidateStatistics;
      });

      statistics = statisticsMap;
      print(statistics);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: statistics.length,
              itemBuilder: (context, index) {
                var electionLocationId = statistics.keys.elementAt(index);
                var candidatesData = statistics[electionLocationId]!;

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Election Location $electionLocationId',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...candidates.map((candidate) {
                          var percentage = candidatesData[candidate.id] ?? 0.0;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${candidate.firstName} ${candidate.lastName}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: double.infinity,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: percentage / 100,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: Stack(
        children: <Widget>[
          Positioned(
            bottom: 200,
            right: 20,
            child: FloatingActionButton(
              onPressed: showCandidateDialog,
              backgroundColor: Colors.green,
              tooltip: 'Candidate',
              child: const Icon(Icons.person_pin_rounded),
            ),
          ),
          Positioned(
            bottom: 140,
            right: 20,
            child: FloatingActionButton(
              onPressed: showElectionLocationDialog,
              backgroundColor: Colors.green,
              tooltip: 'Election Location',
              child: const Icon(Icons.location_city),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: showVoteDialog,
              backgroundColor: Colors.green,
              tooltip: 'Vote',
              child: const Icon(Icons.how_to_vote),
            ),
          ),
          Positioned(
            bottom: 80,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                showElectorDialog();
              },
              backgroundColor: Colors.green,
              tooltip: 'Add Elector',
              child: const Icon(Icons.person_add_alt_outlined),
            ),
          ),
        ],
      ),
    );
  }

  void showVoteDialog() {
    getAll();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade700, Colors.green.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: const Text(
                    'Submit Your Vote',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passportController,
                  decoration: InputDecoration(
                    labelText: 'Passport Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.green.shade400),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedElectionLocationId.isEmpty
                      ? null
                      : selectedElectionLocationId,
                  hint: const Text('Select Election Location'),
                  onChanged: (value) {
                    setState(() {
                      selectedElectionLocationId = value!;
                    });
                  },
                  items: electionLocations.map((location) {
                    return DropdownMenuItem<String>(
                      value: location.id.toString(),
                      child: Text(location.address,
                          style: const TextStyle(color: Colors.green)),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.green.shade400),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value:
                      selectedCandidateId.isEmpty ? null : selectedCandidateId,
                  hint: const Text('Select Candidate'),
                  onChanged: (value) {
                    setState(() {
                      selectedCandidateId = value!;
                    });
                  },
                  items: candidates.map((candidate) {
                    return DropdownMenuItem<String>(
                      value: candidate.id.toString(),
                      child: Text(
                        '${candidate.firstName} ${candidate.lastName} (No. ${candidate.number})',
                        style: const TextStyle(color: Colors.green),
                      ),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.green.shade400),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    vote(passportController.text, selectedElectionLocationId,
                        selectedCandidateId);
                    getAll();
                    getStatistics();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 32),
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Submit Vote',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showCandidateDialog() {
    getAll();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade700, Colors.green.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: const Text(
                    'Add Candidate',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.green.shade400),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.green.shade400),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: numberController,
                  decoration: InputDecoration(
                    labelText: 'Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.green.shade400),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    addCandidate(firstNameController.text,
                        lastNameController.text, numberController.text);
                    getAll();
                    getStatistics();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 32),
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Add Candidate',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showElectionLocationDialog() {
    getAll();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade700, Colors.green.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: const Text(
                    'Add Election Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.green.shade400),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    addElectionLocation(addressController.text);
                    getAll();
                    getStatistics();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 32),
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Add Election Location',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showElectorDialog() {
    getAll();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade700, Colors.green.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: const Text(
                    'Add elector',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passportController,
                  decoration: InputDecoration(
                    labelText: 'Passport Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.green.shade400),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.green.shade400),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.green.shade400),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: dateOfBirthController,
                  decoration: InputDecoration(
                    labelText: 'Date Of Birth',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.green.shade400),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    addElector(
                        firstNameController.text,
                        lastNameController.text,
                        passportController.text,
                        dateOfBirthController.text);
                    getAll();
                    getStatistics();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 32),
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Add elector',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
