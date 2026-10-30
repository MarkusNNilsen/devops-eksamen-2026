package no.pgr301.exam.service;

import org.springframework.stereotype.Service;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.services.rekognition.RekognitionClient;
import software.amazon.awssdk.services.rekognition.model.DetectLabelsRequest;
import software.amazon.awssdk.services.rekognition.model.DetectLabelsResponse;
import software.amazon.awssdk.services.rekognition.model.Image;
import software.amazon.awssdk.services.rekognition.model.Label;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;

import java.util.List;

@Service
public class RekognitionService {

    private final RekognitionClient client;
    private final MeterRegistry registry;

    public RekognitionService(RekognitionClient client, MeterRegistry registry) {
        this.client = client;
        this.registry = registry;
    }

    public List<String> detectLabels(byte[] bytes) {
        DetectLabelsResponse resp = Timer.builder("rekognition.duration")
            .description("Tid brukt på Rekognition detectLabels")
            .register(registry)
            .record(() -> client.detectLabels(DetectLabelsRequest.builder()
            .image(Image.builder().bytes(SdkBytes.fromByteArray(bytes)).build())
            .maxLabels(20)
            .minConfidence(70f)
            .build()));

        return resp.labels().stream().map(Label::name).toList();
    }
}
