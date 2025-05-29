package cool.cfapps.mqtt_publisher.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MessageRequest {

    @NotBlank(message = "Message cannot be blank")
    @Size(min = 1, max = 1000, message = "Message must be between 1 and 1000 characters")
    private String message;

    // Optional: QoS level (0, 1, or 2)
    @Builder.Default
    private int qos = 1;

    // Optional: Retained flag
    @Builder.Default
    private boolean retained = false;
}
