import numpy as np
import pandas as pd
import tensorflow as tf
from tensorflow.keras import layers, Model
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error
from sklearn.preprocessing import StandardScaler

# Load the user and provider datasets
users_df = pd.read_csv("user_data_generated_realistic.csv")
providers_df = pd.read_csv("provider_data_generated.csv")

# Preprocess user and provider data
# Mapping user IDs and provider IDs to a range of integers
user_map = {user: idx for idx, user in enumerate(users_df['User ID'].unique())}
provider_map = {provider: idx for idx, provider in enumerate(providers_df['Provider ID'].unique())}

# Map user IDs and provider IDs to their respective indices
users_df['user_idx'] = users_df['User ID'].map(user_map)
providers_df['provider_idx'] = providers_df['Provider ID'].map(provider_map)

# Calculate the distance between users and providers
def calculate_distance(user_coords, provider_coords):
    return np.linalg.norm(np.array(user_coords) - np.array(provider_coords))

# Create a new column for distance
users_df['coordinates'] = users_df['Coordinates (X, Y)'].apply(lambda x: eval(x))
providers_df['coordinates'] = providers_df['Coordinates (X, Y)'].apply(lambda x: eval(x))

# Create the user-provider interaction matrix with features
interaction_data = []
for _, user_row in users_df.iterrows():
    for _, provider_row in providers_df.iterrows():
        # Calculate distance
        distance = calculate_distance(user_row['coordinates'], provider_row['coordinates'])

        # Construct input features (user_idx, provider_idx, distance, service preferences, clicks, ratings, etc.)
        service_preferences = user_row['Service Category Preferences'].split(', ')  # Split services
        ratings = [float(user_row['Ratings (Plumbing, Housekeeping, etc.)'].split('(')[-1].split(')')[0])]
        clicks = user_row['Number of Requests']  # Number of requests as click feature

        # Extract preferences as binary features for each service
        services = ['Plumbing', 'Electrical Services', 'Housekeeping / Cleaning', 'Carpentry',
                    'Home Appliance Repair', 'Pest Control', 'Painting & Renovation',
                    'Tailoring & Alteration', 'Personal Care (Home Services)', 'Plastering & Tiling',
                    'Auto Repair', 'Tutoring & Educational', 'Babysitting & Childcare', 'Event Planning']
        service_preference_vector = [1 if service in service_preferences else 0 for service in services]

        interaction_data.append([user_row['user_idx'], provider_row['provider_idx'], distance, *ratings, clicks, *service_preference_vector])

# Convert the interaction data into a DataFrame
interaction_df = pd.DataFrame(interaction_data, columns=['user_idx', 'provider_idx', 'distance', 'rating', 'clicks'] + services)

# Define input features
X = interaction_df[['user_idx', 'provider_idx', 'distance', 'clicks'] + services].values
y = interaction_df['rating'].values  # Interaction score (ratings)

# Train-Test Split
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Define the Neural Collaborative Filtering (NCF) Model
def create_ncf_model(num_users, num_providers, embedding_dim=50):
    user_input = layers.Input(shape=(1,), name='user')
    provider_input = layers.Input(shape=(1,), name='provider')

    # User and provider embedding layers
    user_embedding = layers.Embedding(num_users, embedding_dim)(user_input)
    provider_embedding = layers.Embedding(num_providers, embedding_dim)(provider_input)

    # Flatten the embeddings to feed into the neural network
    user_embedding = layers.Flatten()(user_embedding)
    provider_embedding = layers.Flatten()(provider_embedding)

    # Concatenate user and provider embeddings with additional features (distance, clicks, preferences)
    additional_input = layers.Input(shape=(len(services)+2,), name='additional_features')  # +2 for distance and clicks
    x = layers.concatenate([user_embedding, provider_embedding, additional_input])

    # Feed the concatenated input into a fully connected neural network
    x = layers.Dense(128, activation='relu')(x)
    x = layers.Dense(64, activation='relu')(x)
    x = layers.Dense(32, activation='relu')(x)
    output = layers.Dense(1)(x)  # Single output for predicted rating

    # Define the model
    model = Model(inputs=[user_input, provider_input, additional_input], outputs=output)
    model.compile(optimizer='adam', loss='mean_squared_error')

    return model

# Define the model
num_users = len(users_df['user_idx'].unique())
num_providers = len(providers_df['provider_idx'].unique())

ncf_model = create_ncf_model(num_users, num_providers)

# Train the model
history = ncf_model.fit(
    [X_train[:, 0], X_train[:, 1], X_train[:, 2:]],
    y_train,
    epochs=10,
    batch_size=32,
    validation_data=([X_test[:, 0], X_test[:, 1], X_test[:, 2:]], y_test)
)

# Evaluate the model on the test set
y_pred = ncf_model.predict([X_test[:, 0], X_test[:, 1], X_test[:, 2:]])
mse = mean_squared_error(y_test, y_pred)
print(f'Mean Squared Error: {mse}')

# Recommendation: Get the top N recommendations for a user
def recommend_for_user(user_idx, n=5):
    user_input = np.array([user_idx] * num_providers)
    provider_input = np.arange(num_providers)
    distance = np.array([calculate_distance(users_df.loc[user_idx, 'coordinates'], providers_df.loc[i, 'coordinates']) for i in provider_input])
    clicks = np.array([providers_df.loc[i, 'clicks'] for i in provider_input])

    # Encode service preferences as binary features (like above)
    service_preferences = users_df.loc[user_idx, 'Service Category Preferences'].split(', ')
    service_preference_vector = [1 if service in service_preferences else 0 for service in services]

    # Combine all features (user, provider, distance, clicks, service preferences)
    additional_features = np.vstack([distance, clicks, service_preference_vector]).T

    # Predict ratings for all providers for this user
    predictions = ncf_model.predict([user_input, provider_input, additional_features])

    # Get top N provider recommendations based on predicted rating
    top_n_idx = predictions.flatten().argsort()[-n:][::-1]
    top_providers = provider_input[top_n_idx]
    return top_providers

# Example: Recommend top 5 providers for a user
top_providers = recommend_for_user(user_idx=0, n=5)
print(f'Top 5 recommended providers for user 0: {top_providers}')
