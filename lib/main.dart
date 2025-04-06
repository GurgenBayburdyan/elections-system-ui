import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'Candidate.dart';
import 'ElectionLocation.dart';
import 'Elector.dart';

void main() {
  runApp(const ElectionSystemApp());
}

class ElectionSystemApp extends StatelessWidget {
  const ElectionSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Election System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const VoteScreen(title: "Vote for Election"),
      debugShowCheckedModeBanner: false,
    );
  }
}

class VoteScreen extends StatefulWidget {
  const VoteScreen({super.key, required this.title});

  final String title;

  @override
  State<VoteScreen> createState() => VoteScreenState();
}

class VoteScreenState extends State<VoteScreen> {
  String selectedElectorId = '';
  String selectedElectionLocationId = '';
  String selectedCandidateId = '';

  List<Elector> electors = [];
  List<ElectionLocation> electionLocations = [];
  List<Candidate> candidates = [];

  String electorsUrl = "http://localhost:8080/electors";
  String electionLocationsUrl = "http://localhost:8080/electionLocation";
  String candidatesUrl = "http://localhost:8080/candidates";

  @override
  void initState() {
    super.initState();
    getAll();
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

  Future<void> vote() async {
    final voteData = {
      'electorId': selectedElectorId,
      'electionLocationId': selectedElectionLocationId,
      'candidateId': selectedCandidateId,
    };

    final response = await http.post(
      Uri.parse('http://localhost:8080/votes'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(voteData),
    );

    final data = json.decode(response.body);

    if (data['errorType']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vote successfully submitted!')),
      );
    }
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedElectorId.isEmpty ? null : selectedElectorId,
                    hint: const Text('Select Elector'),
                    onChanged: (value) {
                      setState(() {
                        selectedElectorId = value!;
                      });
                    },
                    items: electors.map((elector) {
                      return DropdownMenuItem<String>(
                        value: elector.id.toString(),
                        child: Text('${elector.firstName} ${elector.lastName}'),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
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
                        child: Text(location.address),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCandidateId.isEmpty
                        ? null
                        : selectedCandidateId,
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
                            '${candidate.firstName} ${candidate.lastName}'),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (!(selectedElectorId.isEmpty ||
                          selectedElectionLocationId.isEmpty ||
                          selectedCandidateId.isEmpty)) {
                        vote();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 32),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Submit Vote',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
